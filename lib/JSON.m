% COPYRIGHT Wolfgang Kuehn 2015-2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON < handle
    
    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
        levelsToLog = { 'WARNING', 'INFO' };
        %levelsToLog = { 'DEBUG', 'WARNING', 'INFO' };
    end
    
    properties %(Access = private)
        errors
        formatters
        schemasByURI
    end
    
    methods
        
        function this = JSON()
            this.formatters = containers.Map();
        end
        
        function uri = resolveURIagainstLoadPath(this, uri)
            %resolveURIagainstLoadPath resolves the reference against the base URI and normalizes.
            % See https://tools.ietf.org/html/rfc3986

            try
                r = javaObject('java.net.URI', uri);
            catch e
                error('JSON:URI', 'Could not resolve URI %s because: %s', uri, e.message);
            end
            
            if isempty(r.getScheme())
                % Relative reference
                location = which(uri);
                if isempty(location)
                    error('JSON:URI', 'Could not resolve URI %s', uri);
                end
                uri = ['file:///' strrep(location, '\', '/')];
            end
        end
        
        function schema = loadSchema(this, schema)
        % schema is one of
        %   * empty
        %   * a resolved schema
        %   * a URI
        %   * a string containing the JSON-Schema
        %
            if ischar(schema)
                schema = strtrim(schema);
            end

            if isempty(schema)
                schema = [];
                return;
            elseif this.isaMap(schema)
                % This is already a resolved schema.
                return;
            elseif ischar(schema)
                % pass
            else
                error('Invalid type for schema: %s', class(schema));
            end

            this.schemasByURI = containers.Map();
            
            if isempty(regexp(schema, '^\s*\{', 'ONCE')) % A URI cannot start with an opening curly, but a schema will
                uri = this.resolveURIagainstLoadPath(schema);
                schema = this.getSchemaByURI(uri);
            else
                error('TODO: Remove this code')
                %uri = '';
                %schema = this.postLoadSchema(schema, uri);
                %this.schemasByURI(uri) = schema;
            end

        end
        
        function addError(this, pointer, msg, value, type)
            if nargin < 5
                type = 'JSON:SCHEMA_VALIDATION';
            end
            
            if isstruct(value) || JSON.isaMap(value)
                value = '{object}';
            elseif iscell(value)
                value = '[array]';
            elseif islogical(value)
                value = mat2str(value);
            elseif isnumeric(value)
                value = num2str(value);
            end
            this.errors{end+1} = {pointer msg value type};
        end
        
        function childSchema = getPropertySchema(this, schema, key)
            assert(ischar(key));
            
            if isempty(schema) % Shortcut
                childSchema = [];
                return;
            end
            
            subpath = ['/properties/' key];
            childSchema = JSON.getPath(schema, subpath);            
            
            if isempty(childSchema) && schema.isKey('patternProperties')
                patternProperties = schema('patternProperties');
                patterns = patternProperties.keys();
                for k=1:length(patterns)
                    if ~isempty(regexp(key, patterns{k}, 'ONCE'))
                        childSchema = patternProperties(patterns{k});
                        break;
                    end
                end
            end

            if ~isempty(childSchema)
                this.normalizeSchema(childSchema, schema('__resolutionScope'), subpath);
            end
        end
        
        function childSchema = getItemSchema(this, schema, key)
            % TODO: Only call this for array items.
            assert(isnumeric(key) && ~rem(key, 1));
            childSchema = [];
            
            items = JSON.getPath(schema, '/items');

            if isempty(items) % Shortcut
                return;
            end

            if JSON.isaMap(items)
                childSchema = items;
                subpath = 'items/';
            elseif iscell(items) && key < length(items)
                childSchema = items{key+1};
                subpath = [sprintf('items/%d/', key)];
            end

            if ~isempty(childSchema)
                this.normalizeSchema(childSchema, schema('__resolutionScope'), subpath);
            end
        end

        function subSchema = getSubSchema(this, schema, pointer)
            subSchema = JSON.getPath(schema, pointer);

            if ~isempty(subSchema)
                this.normalizeSchema(subSchema, schema('__resolutionScope'), pointer);
            end

            if subSchema.isKey('$ref')
                subSchema = subSchema('__refSchema');
            end
        end
        
        function mergedSchema = mergeSchemas(this, schema)
            %MERGESCHEMAS Summary of this function goes here
            %   Detailed explanation goes here
            
            % Merge properties and required fields of all schemas.
            mergedSchema = containers.Map();
            mergedSchema('type') = {'object'};
            mergedProperties = containers.Map();
            mergedSchema('properties') = mergedProperties;
            mergedSchema('required') = {};
            allOf = schema('allOf');
            
            for k=1:length(allOf)
                subSchema = allOf{k};
                % TODO: Assert properties is member
                props = subSchema('properties');
                keys = props.keys();
                for l=1:length(keys)
                    key = keys{l};
                    mergedProperties(key) = props(key);
                end
                
                if subSchema.isKey('required')
                    if mergedSchema.isKey('required')
                        mergedSchema('required') = [mergedSchema('required') subSchema('required')];
                    else
                        mergedSchema('required') = subSchema('required');
                    end
                end
            end
        end
        
        function pType = inferePrimitiveType(this, value, schema, pointer)
            
            type = schema('type');
            pType = [];
            
            if isempty(type); return; end;
            
            if isempty(value)
                pType = type{1};
            else
                n = numel(value);
                
                if ischar(value)
                    if ismember('string', type)
                        pType = 'string';
                    end
                elseif isstruct(value) || JSON.isaMap(value)
                    if n==1 && ismember('object', type)
                        pType = 'object';
                    elseif ismember('array', type)
                        pType = 'array';
                    end
                elseif iscell(value)
                    if ismember('array', type)
                        pType = 'array';
                    end
                elseif isnumeric(value)
                    if n == 1
                        if isnan(value)
                            if ismember('null', type)
                                pType = 'null';
                            end
                        elseif rem(value, 1) == 0 % integer value
                            if ismember('integer', type)
                                pType = 'integer';
                            elseif ismember('number', type)
                                pType = 'number';
                            end
                        elseif ismember('number', type)
                            pType = 'number';
                        end
                    end
                    
                    if isempty(pType) && ismember('array', type)
                        pType = 'array';
                    end
                elseif islogical(value)
                    if n == 1 && ismember('boolean', type)
                        pType = 'boolean';
                    elseif ismember('array', type)
                        pType = 'array';
                    end
                end
                
                if isempty(pType)
                    this.addError(pointer, sprintf('does not match type %s', strjoin(type, ' or ')), value);
                    return
                end
            end
        end
        
        function validate(this, value, pType, schema, pointer)
            
            function p = getBadPath(pointer, indices)
                isVec = length(indices) > 1;
                indices = find(indices);
                if isempty(indices)
                    p = [];
                elseif isVec
                    p = [pointer num2str(indices)];
                else
                    p = pointer;
                end
            end
            
            if strcmp(pType, 'object')
                
                if isstruct(value)
                    s = fieldnames(value);
                else
                    s = value.keys();
                end
                
                if schema.isKey('required')
                    required = schema('required');
                    for k=1:length(required)
                        if ~ismember(required{k}, s)
                            this.addError(pointer, sprintf('is missing required field %s', required{k}), value);
                        end
                    end
                end
                
                if schema.isKey('minProperties') && length(s) < schema('minProperties')
                    this.addError(pointer, sprintf('has less than %g properties', schema('minProperties')), value);
                end
                
                if schema.isKey('maxProperties') && length(s) > schema('maxProperties')
                    this.addError(pointer, sprintf('has more than %g properties', schema('maxProperties')), value);
                end
                
                if JSON.getPath(schema, '/additionalProperties') == false
                    p = JSON.getPath(schema, '/properties', containers.Map());
                    p = p.keys();
                    s = s(~ismember(s, p));
                    pP = JSON.getPath(schema, '/patternProperties', containers.Map());
                    pp = pP.keys();
                    sFound = {};
                    for l=1:length(pp)
                        pattern = pp{l};
                        for k=1:length(s)
                            if ~isempty(regexp(s{k}, pattern, 'ONCE'))
                                sFound{end+1} = s{k};
                                break;
                            end
                        end
                    end
                    
                    sNotFound = s(~ismember(s, sFound));
                    for k=1:length(sNotFound)
                        this.addError(pointer, 'contains additional property', sNotFound{k});
                    end
                end
                
                if schema.isKey('enum')
                    this.addError(pointer, 'is not contained in enumeration', value);
                end
                
            elseif ischar(value)
                
                if schema.isKey('pattern') && isempty(regexp(value, schema('pattern'), 'ONCE'))
                    this.addError(pointer, sprintf('does not match pattern %s', schema('pattern')), value);
                end
                
                if schema.isKey('minLength') && length(value) < schema('minLength')
                    this.addError(pointer, sprintf('has length less than %g', schema('minLength')), value);
                end
                
                if schema.isKey('maxLength') && length(value) > schema('maxLength')
                    this.addError(pointer, sprintf('has length greater than %g', schema('maxLength')), value);
                end
                
                format = JSON.getPath(schema, '/format');
                
                if strcmp(format, 'date')
                    if isempty(regexp(value, '^\d{4}-\d{2}-\d{2}$', 'ONCE'))
                        this.addError(pointer, 'is not a valid date', value);
                    end
                end
                
                if schema.isKey('enum')
                    enum = schema('enum');
                    if ~iscellstr(enum) || ~ismember(value, enum)
                        this.addError(pointer, 'is not contained in enumeration', value);
                    end
                end
                
            elseif ismember(pType, {'integer' 'number'})
                
                if strcmp(pType, 'integer') && rem(value, 1)
                    this.addError(pointer, 'is not an integer', value);
                end
                
                if schema.isKey('multipleOf') && rem(value, schema('multipleOf'))
                    this.addError(pointer, sprintf('is not a multiple of %g', schema('multipleOf')), value);
                end
                
                if schema.isKey('minimum')
                    if schema.isKey('exclusiveMinimum') && schema('exclusiveMinimum')
                        idx = value <= schema('minimum');
                    else
                        idx = value < schema('minimum');
                    end
                    badPath = getBadPath(pointer, idx);
                    if ~isempty(badPath)
                        this.addError(badPath, sprintf('violates minimum %g', schema('minimum')), value);
                    end
                end
                
                if schema.isKey('maximum')
                    if schema.isKey('exclusiveMaximum') && schema('exclusiveMaximum')
                        idx = value >= schema('maximum');
                    else
                        idx = value > schema('maximum');
                    end
                    badPath = getBadPath(pointer, idx);
                    if ~isempty(badPath)
                        this.addError(badPath, sprintf('violates maximum %g', schema('maximum')), value);
                    end
                end
                
                if schema.isKey('enum')
                    enum = schema('enum');
                    if ~isnumeric(enum) || ~ismember(value, enum)
                        this.addError(pointer, 'is not contained in enumeration', value);
                    end
                end
                
            elseif strcmp(pType, 'array')
                
                if schema.isKey('additionalItems') && ~schema('additionalItems') && ...
                        schema.isKey('items') && iscell(schema('items')) && length(value)>length(schema('items'))
                    this.addError(pointer, sprintf('does not allow additional items'), '[array]');
                end
                
                if schema.isKey('minItems') && length(value) < schema('minItems')
                    this.addError(pointer, sprintf('has less than %g items', schema('minItems')), '[array]');
                end
                
                if schema.isKey('maxItems') && length(value) > schema('maxItems')
                    this.addError(pointer, sprintf('has more than %g items', schema('maxItems')), '[array]');
                end
                
                if schema.isKey('enum')
                    this.addError(pointer, 'is not contained in enumeration', value);
                end
                
            elseif strcmp(pType, 'array')
                if schema.isKey('enum')
                    this.addError(pointer, 'is not contained in enumeration', value);
                end
            elseif strcmp(pType, 'boolean')
                if schema.isKey('enum')
                    enum = schema('enum');
                    if ~islogical(enum) || ~ismember(value, enum)
                        this.addError(pointer, 'is not contained in enumeration', value);
                    end
                end
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
        
        function resolvedURI = resolveURI( this, uri, base)
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
        
        function schema = postLoadSchema(this, schema, uri)
            parser = JSON_Parser();
            parser.isSchema = true;
            [ schema, errs] = parse(parser, schema, [], struct('objectFormat', 'Map'));
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

            this.normalizeSchema(schema, schema('id'), '/');
        end

        function normalizeSchema(this, schema, resolutionScope, pointer)
            if ~JSON.isaMap(schema)
                error('JSON:PARSE_SCHEMA', 'A JSON Schema MUST be an object, found %s', class(schema));
            end

            if schema.isKey('__isNormalized')
                return
            end
                
            JSON.log('DEBUG', 'normalizeSchema %s', pointer);
            
            
            
            if schema.isKey('$ref')
                ref = schema('$ref');
                if ~ischar(ref)
                    % TODO: use addError and make that throw
                    error('JSON:PARSE_SCHEMA', '$ref must be a string at %s', pointer);
                end

                %keyboard()

                ref = this.resolveURI(ref, resolutionScope);

                % foo#bar->/bar or foo#->/ or foo->/
                refPointer = regexprep(ref, '[^#]*(#/?|$)', '/', 'once');
                
                schema('__refSchema') = JSON.getPath(this.getSchemaByURI(ref), refPointer);
            end
            
            if schema.isKey('id') && ~isempty(schema('id'))
                % Change resolution scope.
                % Note that we do this AFTER processing $ref.
                schema('__resolutionScope') = this.resolveURI(schema('id'), resolutionScope);
                resScopURI = javaObject('java.net.URI', resolutionScope);
                if ~resScopURI.isAbsolute()
                    error('JSON:PARSE_SCHEMA', 'Resolved URI must be absolute: %s', resolutionScope);
                end
            else
                schema('__resolutionScope') = resolutionScope;
            end
            
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
            %elseif schema.isKey('manyKeyword')
            %    manyKeyword = schema('manyKeyword');
            %    manySchema = schema(manyKeyword);
            %    for k=1:length(manySchema)
            %        subPath = [pointer '/' manyKeyword '/' num2str(k-1)];
            %        addSchema(manySchema{k}, subPath, resolutionScope);
            %    end
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

            schema('__isNormalized') = true;
            
        end
        
    end % methods (Access=private)
    
    methods (Static)
        
        function b = isaMap(obj)
            if JSON.isoct
                b = isa(obj, 'Map');
            else
                b = isa(obj, 'containers.Map');
            end
        end
        
        function log(level, fmt, varargin)
            if ismember(level, JSON.levelsToLog)
                fprintf(1, [level ' ' fmt '\n'], varargin{:});
            end
        end
              
        function [value, errors] = parse(varargin)
            parser = JSON_Parser();
            [value, errors] = parse(parser, varargin{:});
        end
        
        function [json, errors] = stringify(varargin)
            stringifier = JSON_Stringifier();
            [json, errors] = stringifier.stringify(varargin{:});
        end

        function schema = parseSchema(schemaURL)
            json = JSON();
            schema = json.loadSchema(schemaURL);
        end
        
        function obj = setPath(obj, pointer, value)
            %SETPATH sets the value referenced by the pointer.
            % Example
            %   m = containers.Map()
            %   m('foo') = containers.Map();
            %   c = m('foo');
            %   c('bar') = {1 2 3};
            %   JSON.setPath(m, '/foo/bar/1', 42)   -> replaces 2 by 42
            
            if isempty(pointer)
                obj = value;
            else
                tokens = strsplit(pointer, '/');
                [~, chain] = JSON.getPath(obj, pointer);
                
                c = chain{end};
                if iscell(c)
                    k = length(chain);
                    idx = struct('type', '{}');
                    idx.subs = {};
                    while iscell(c) && k >= 1
                        index = str2double(tokens{k+1});
                        if ischar(index) || isnan(index)
                            error('cell array must be indexed by a positive integer, was %s', tokens{k+1});
                        end
                        idx.subs = [(index+1) idx.subs];
                        k = k-1;
                        if k==0
                            break
                        else
                            c = chain{k};
                        end
                    end
                    
                    if k==0
                        obj = subsasgn(c, idx, value);
                    else
                        % Octave Bug(?): Without builtin, and if value is of class Map,
                        % then subsasgn() calls Map.subsasgn(), even if the lhs c(tokens{k+1})
                        % is not a Map (confirmed with a cell array).
                        c(tokens{k+1}) = builtin ('subsasgn', c(tokens{k+1}), idx, value);
                    end
                else
                    assert(JSON.isaMap(c));
                    c(tokens{end}) = value;
                end
            end
        end
        
        function [obj, chain] = getPath(obj, pointer, default)
            %GETPATH returns the value referenced by the pointer.
            % The pointer must be a JSON pointer, so each reference token must be
            % prefixed by / and numerical tokens referencing an array are zero-based.
            % Returns default or empty if the pointer does not resolve.
            % See https://tools.ietf.org/html/rfc6901
            %
            % Examples:
            %    obj = containers.Map();
            %    obj('foo') = struct('bar', 13);
            %    obj('bar') = {'foo' 'bar'};
            %    obj('foo/bar') = 42;                   % Not recommended!
            %    JSON.getPath(obj, '/foo/bar')          % -> 13
            %    JSON.getPath(obj, '/bar/1')            % -> 'bar'
            %    JSON.getPath(obj, '/foo~1bar')         % -> 42
            %    JSON.getPath(obj, '/foobar', 4711)     % -> 4711
            
            chain = {};
            
            if isempty(pointer)
                if isempty(obj)
                    obj = default;
                end
                return;
            end
            
            if pointer(1) ~= '/'
                % TODO: Do not throw here
                error('Invalid pointer syntax: %s', pointer);
            end
            
            tokens = strsplit(pointer, '/');
            
            for k = 2:length(tokens)
                chain{end+1} = obj;
                token = tokens{k};
                % '~' needs to be encoded as '~0' and '/' needs to be encoded as '~1'
                token = strrep(strrep(token, '~0', '~'), '~1', '/');
                
                if JSON.isaMap(obj) && obj.isKey(token)
                    obj = obj(token);
                    continue;
                end
                
                if iscell(obj) && ~isempty(regexp(token, '^\d+$', 'once'))
                    l = str2double(token);
                    if l < length(obj) % This will also handle l is not a number
                        obj = obj{l+1};
                        continue;
                    end
                end
                
                if isstruct(obj) && isfield(obj, token)
                    obj = obj.(token);
                    continue;
                end
                
                if nargin >= 3
                    obj = default;
                else
                    obj = [];
                end
                break;
            end
            
        end
        
        %         function text = ___readFileToString(pointer, encoding )
        %             if JSON.isoct
        %                 [fid, msg] = fopen(pointer, 'r');
        %             else
        %                 [fid, msg] = fopen(pointer, 'r', 'l', encoding);
        %             end
        %
        %             if fid == -1
        %                 % TODO: Do not throw here
        %                 error('Could not open %s: %s', pointer, msg);
        %             end
        %
        %             text = fscanf(fid, '%c');
        %             fclose(fid);
        %         end
        
        function [d, err] = datetimestring2datetime(s)
            %datetimestring2datetime parses an ISO8601 date-time into a datetime object.
            % Allowed formats are
            %   yyyy-MM-ddTHH:mm:ssXX
            %   yyyy-MM-ddTHH:mmXX
            %   yyyy-MM-ddTHHXX
            % where XX is of the form Z or +0100 or +01:00
            %
            % Example:
            %     JSON.datestring2datetime('2016-02-02T00:00Z')
            
            tokens = regexp(s, '^(\d{4}-\d{2}-\d{2}T\d{2})(:\d{2})?(:\d{2})?(Z|(\+|\-)\d{2}:?\d{2})$', 'tokens', 'once');
            
            if isempty(tokens)
                d = s;
                err = 'is not a valid date-time';
                return;
            end
            
            fmt = 'yyyy-MM-dd''T''HH';
            if ~isempty(tokens{2})
                fmt = [fmt ':mm'];
            end
            if ~isempty(tokens{3})
                fmt = [fmt ':ss'];
            end
            
            fmt = [fmt 'XX'];
            
            try
                d = datetime(s, 'InputFormat', fmt, 'TimeZone', 'UTC', 'Format', 'preserveinput');
            catch e
                err = e.message;
                d = s;
                return
            end
            err = [];
        end
        
        function [d, err] = datestring2datetime(s)
            %datestring2datetime parses an ISO8601 date into a datetime object.
            % Allowed formats are yyyy-MM-dd
            %
            % Example:
            %     JSON.datestring2datetime('2016-02-02')
            
            tokens = regexp(s, '^(\d{4}\-\d{2}\-\d{2})$', 'tokens', 'once');
            
            if isempty(tokens)
                d = s;
                err = 'is not a valid date';
                return;
            end

            try
                d = datetime(s, 'InputFormat', 'yyyy-MM-dd', 'TimeZone', '', 'Format', 'preserveinput');
            catch e
                err = e.message;
                d = s;
                return
            end
            err = [];
        end
        
        function [s, err] = datetime2string(d)
            %datetime2string converts a datetime object to an ISO8601 string
            
            if ~isa(d, 'datetime')
                err = 'is not a valid date';
                s = d;
                return;
            end
            
            
            if isempty(d.TimeZone)
                % TODO: We should set the format on a clone!
                d.Format = 'yyyy-MM-dd';
            else
                d.Format = 'yyyy-MM-dd''T''HH:mm:ssXX';
            end
            s = char(d);
            err = [];
        end
        
    end
end


