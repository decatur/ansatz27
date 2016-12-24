% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_SchemaLoader < JSON_Parser
    %JSON_PARSER Validating JSON parser
    % See https://github.com/decatur/ansatz27
    
    properties %(Access = private)
        schemasByURI
    end
    
    methods
        
        function this = JSON_SchemaLoader()
            %this@JSON();
            this.schemasByURI = containers.Map();
            this.formatters('date') = @(s) JSON.datestring2datetime(s);
            this.formatters('date-time') = @(s) JSON.datetimestring2datetime(s);
        end
    
        function schema = load(this, uri)
            uri = JSON.resolveURIagainstLoadPath(strtrim(uri));
            schema = this.getSchemaByURI(uri);
        end

        function childSchema = getPropertySchema(this, schema, key)
            assert(ischar(key));
            
            if isempty(schema) % Shortcut
                childSchema = [];
                return;
            end
            
            pointer = ['/properties/' key];
            childSchema = this.getSubSchema(schema, pointer);

            if ~isempty(childSchema)
                return
            end
            
            if schema.isKey('patternProperties')
                patternProperties = schema('patternProperties');
                patterns = patternProperties.keys();
                for k=1:length(patterns)
                    if ~isempty(regexp(key, patterns{k}, 'ONCE'))
                        childSchema = this.getSubSchema(schema, ['/patternProperties/' patterns{k}]);
                        return;
                    end
                end
            end

        end
        
        function itemSchema = getItemSchema(this, schema, key)
            % TODO: Only call this for array items.
            assert(isnumeric(key) && ~rem(key, 1));
            itemSchema = [];

            if isempty(schema)
                return
            end
            
            items = JSON.getPath(schema, '/items');

            if isempty(items) % Shortcut
                return;
            end

            if JSON.isaMap(items)
                itemSchema = this.getSubSchema(schema, '/items');
            elseif iscell(items) && key < length(items)
                itemSchema = this.getSubSchema(schema, sprintf('/items/%d', key));
            end
        end

        function schema = getSubSchema(this, schema, pointer)
            if isempty(schema)
                return
            end

            referencingSchemas = containers.Map();
            ref = [];

            while true
                id = schema('id');
                [schema] = JSON.getPath(schema, pointer);

                
                if isempty(schema) || ~JSON.isaMap(schema)
                    if ~isempty(ref)
                        error('JSON:PARSE_SCHEMA', '$ref is invalid: %s', ref);
                    end
                    schema = [];
                    return
                end

                if schema.isKey('__refSchema')
                    schema = schema('__refSchema');
                    return
                end

                schema('id') = id;

                if ~schema.isKey('$ref')
                    break;
                end
            
                ref = schema('$ref');
                JSON.log('DEBUG', 'resolveSchemaRef %s', ref);

                if ~ischar(ref)
                    % TODO: use addError and make that throw
                    error('JSON:PARSE_SCHEMA', '$ref must be a string, found %s', class(ref));
                end

                ref = this.resolveURI(ref, schema('id'));
                if referencingSchemas.isKey(ref)
                    error('JSON:PARSE_SCHEMA', 'Cyclic references at %s', ref);
                end
            
                referencingSchemas(ref) = schema;

                resScopURI = javaObject('java.net.URI', ref);
                if ~resScopURI.isAbsolute()
                    error('JSON:PARSE_SCHEMA', 'Resolved URI must be absolute: %s', ref);
                end

                % Extract the anchor.
                pointer = regexprep(ref, '[^#]*#?', '', 'once');
                if ~isempty(pointer)
                    pointer = ['/' pointer];
                end
                schema = this.getSchemaByURI(ref);
            end

            if ~schema.isKey('__isNormalized')
                this.normalizeSchema(schema, pointer);
            end

            refs = referencingSchemas.keys();

            for k=1:length(refs)
                referencingSchema = referencingSchemas(refs{k});
                referencingSchema('__refSchema') = schema;
            end

        end
        
    end % methods

    methods (Access=private)
        
        function schema = getSchemaByURI(this, uri)
            parts = strsplit(uri, '#');
            uri = parts{1};
            JSON.log('DEBUG', 'getSchemaByURI %s', uri);
            
            if this.schemasByURI.isKey(uri)
                schema = this.schemasByURI(uri);
                return
            end
            
            JSON.log('DEBUG', 'Not in cache, now loading');
            try
                schema = urlread(uri);
            catch e
                error('JSON:PARSE_SCHEMA', 'Could not read schema from %s because: %s', uri, e.message);
            end
            
            if isempty(strtrim(schema))
                % libcurl will return empty string if file uri points to directory.
                error('JSON:PARSE_SCHEMA', 'No schema at %s', uri);
            end
            
            schema = this.postLoadSchema(schema, uri);
            this.schemasByURI(uri) = schema;
        end

        function schema = postLoadSchema(this, schema, uri)

            [ schema, errs] = this.parse_(schema, [], struct('objectFormat', 'Map'));
            if ~isempty( errs)
                this.errors = errs;
                error('JSON:PARSE_SCHEMA', 'Parse error in schema %s', uri);
            end

            if ~schema.isKey('id')
                % [7.1 Core] The initial resolution scope of a schema is the URI of the schema itself, if any, or the empty URI if the schema was not loaded from a URI.
                schema('id') = uri;
            else
                schema('id') = this.resolveURI(schema('id'), uri);
            end

            schema = this.getSubSchema(schema, '');
        end

        function resolvedURI = resolveURI(this, uri, base)
            %resolveURI resolves the reference against the base URI.
            % See https://tools.ietf.org/html/rfc3986
            resolvedURI = uri;
            if ~isempty(base)
                base = javaObject('java.net.URI', base);
                resolvedURI = char(base.resolve(uri));
                % Workaround for a Java bug. Resolved uri may look like file://foo/bar. We need for slashes after the protocol.
                resolvedURI = regexprep (resolvedURI, 'file:/+', 'file:////');
            end
        end

        function normalizeSchema(this, schema, pointer)
            if ~JSON.isaMap(schema)
                error('JSON:PARSE_SCHEMA', 'A JSON Schema MUST be an object, found %s', class(schema));
            end
                
            JSON.log('DEBUG', 'normalizeSchema %s', pointer);
            
            manyKeywords = {'allOf', 'anyOf', 'oneOf'};
            manyCount = 0;
            
            % Find how many manyKeywords are present and save the last.
            for k=1:length(manyKeywords)
                manyKeyword = manyKeywords{k};
                if schema.isKey(manyKeyword)
                    manyCount = manyCount + 1;
                    schema('manyKeyword') = manyKeyword;
                end
            end
            
            if manyCount > 1
                error('JSON:PARSE_SCHEMA', 'Only one of %s allowed', strjoin(manyKeywords, ', '));
            elseif schema.isKey('allOf')
                this.mergeSchemas(schema);
            end
            
            if ~schema.isKey('type') || isempty(schema('type'))
                schema('type') = {};
            end
            
            type = schema('type');
            
            if ischar(type)
                type = {type};
                schema('type') = type;
            end
            
            if schema.isKey('required')
                if isempty(schema('required'))
                    schema('required') = {};
                elseif ~iscell(schema('required'))
                    error('JSON:PARSE_SCHEMA', 'Invalid required at %s', pointer);
                end
            end
            
            if schema.isKey('pattern') && ~ischar(schema('pattern'))
                error('JSON:PARSE_SCHEMA', 'Pattern must be a string at %s', pointer);
            end

            if schema.isKey('default')
                p = JSON_Parser();
                [ defaultValue, errs ] = parse(p, schema('default'), schema);
                if ~isempty( errs)
                    error('JSON:PARSE_SCHEMA', 'Default value does not validate in schema %s', pointer);
                end
                schema('default') = defaultValue;
            end

            schema('__isNormalized') = true;
            
        end

        function mergeSchemas(this, schema)
            %MERGESCHEMAS Summary of this function goes here
            %   Detailed explanation goes here
            
            % Merge properties and required fields of all schemas.
            mergedProperties = containers.Map();
            schema('properties') = mergedProperties;
            schema('required') = {};
            allOf = schema('allOf');
            
            for k=1:length(allOf)
                subSchema = this.getSubSchema(schema, ['/allOf/' num2str(k-1)]);
                % TODO: Assert properties is member
                props = subSchema('properties');
                keys = props.keys();
                for l=1:length(keys)
                    key = keys{l};
                    mergedProperties(key) = props(key);
                end
                
                if subSchema.isKey('required')
                    schema('required') = [schema('required') subSchema('required')];
                end
            end

            schema.remove('allOf');
        end

    end % methods (Access=private)
        
end

