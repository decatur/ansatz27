% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON < handle
    
    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    end
    
    properties %(Access = private)
        errors
        formatters
        schemaCache
    end
    
    methods
        
        function this = JSON()
            this.formatters = containers.Map();
            this.schemaCache = containers.Map();
        end
        
        function schema = loadSchema(this, schema)      
            if ischar(schema)
                if 1 == regexp(schema, '^file:')
                    schemaURL = regexprep(schema, '^file:', '');
                    schema = JSON.readFileToString(schemaURL, 'latin1');
                end
                schema = JSON.parse(schema, [], struct('objectFormat', 'Map'));
            else
                error('JSON:PARSE_SCHEMA', 'Schema must be of type char');
            end
        end
        
        function addError(this, path, msg, value, type)
            if nargin < 5
                type = 'JSON:SCHEMA_VALIDATION';
            end
            
            if isstruct(value) || isa(value, 'Map')
                value = '{object}';
            elseif iscell(value)
                value = '[array]';
            elseif islogical(value)
                value = mat2str(value);
            elseif isnumeric(value)
                value = num2str(value);
            end
            this.errors{end+1} = {path msg value type};
        end
        
        function childSchema = getChildSchema(this, schema, key)
            childSchema = [];
            
            if isempty(schema)
                return;
            end
            
            if ischar(key)
                if ismember('object', JSON.getPath(schema, '/type'))
                    childSchema = JSON.getPath(schema, ['/properties/' key]);
                    if ~isempty(childSchema)
                        return;
                    end

                    if schema.isKey('patternProperties')
                        patternProperties = schema('patternProperties');
                        patterns = patternProperties.keys();
                        for k=1:length(patterns)
                            if ~isempty(regexp(key, patterns{k}))
                                childSchema = patternProperties(patterns{k});
                                break;
                            end
                        end
                    end
                end
            elseif isnumeric(key)
                items = JSON.getPath(schema, '/items');
                if isa(items, 'Map')
                    childSchema = items;
                elseif iscell(items)
                    childSchema = items{key};
                end
            end
        end
        
        function schema = normalizeSchema(this, schema, path)
            %normalizeSchema recursively descends the schema and resolves allOf references.
            if nargin < 3
                path = '';
            end
            schema = normalizeSchema_(this, schema, schema, path);
        end
        
        
        function schema = resolveRef(this, rootSchema, schema, path)
            %resolveRef swaps in the referenced schema.
            
            refs = {['#' path]};

            while schema.isKey('$ref')
                ref = schema('$ref');
                
                if ~ischar(ref) || isempty(strtrim(ref))
                    error('JSON:PARSE_SCHEMA', 'Invalid $ref at %s', strjoin(refs, ' -> '));
                end
                
                ref = strtrim(ref);
                if ref(1) == '#'
                    ref = [JSON.getPath(rootSchema, '/url', '') ref];
                end
                
                if ismember(ref, refs)
                    error('JSON:PARSE_SCHEMA', 'Cyclic references %s', strjoin([refs ref], ' -> '));
                end
                
                refs{end+1} = ref;
                
                parts = strsplit(ref, '#');
                
                if ~isempty(parts{1})
                    url = ['file:' parts{1}];
                    if this.schemaCache.isKey(url)
                        rootSchema = this.schemaCache.isKey(url);
                    else
                        fprintf(1, 'Loading schema %s\n', url);
                        rootSchema = this.loadSchema(url);
                        this.schemaCache(url) = rootSchema;
                        schema = rootSchema;
                    end
                end
                
                if length(parts) == 2
                    schema = JSON.getPath(rootSchema, parts{2});
                    if isempty(schema)
                        error('JSON:PARSE_SCHEMA', 'Invalid $ref at %s', strjoin(refs, ' -> '));
                    end
                end
            end
        end
        
        function schema = normalizeSchema_(this, rootSchema, schema, path)
            function processProperties(schema, propertyType)
                if schema.isKey(propertyType) && ~isempty(schema(propertyType))
                    props = schema(propertyType);
                    pNames = props.keys();
                    for k=1:length(pNames)
                        subPath = [path '/' propertyType '/' pNames{k}];
                        props(pNames{k}) = this.normalizeSchema_(rootSchema, props(pNames{k}), subPath);
                    end
                    schema(propertyType) = props;
                end
            end


            if ~isa(schema, 'Map')
                error('JSON:PARSE_SCHEMA', 'A JSON Schema MUST be an object');
            end
            
            if schema.isKey('$ref')
                schema = this.resolveRef(rootSchema, schema, path);
            end
            
            if schema.isKey('allOf')
                schema = this.mergeSchemas(rootSchema, schema);
            end
            
            if ~schema.isKey('type') || isempty(schema('type'))
                schema('type') = {};
                return
            end
            
            type = schema('type');
            
            if ischar(type)
                type = {type};
                schema('type') = type;
            end
                        
            if schema.isKey('required') && ~iscell(schema('required'))
                error('JSON:PARSE_SCHEMA', 'Invalid required at %s', path);
            end

            if schema.isKey('pattern') && ~ischar(schema('pattern'))
                error('JSON:PARSE_SCHEMA', 'Pattern must be a string at %s', path);
            end

            processProperties(schema, 'properties');
            processProperties(schema, 'patternProperties');

            if ismember('array', type) && schema.isKey('items')
                items = schema('items');
                if isa(items, 'Map')
                    schema('items') = this.normalizeSchema_(rootSchema, items, [path '/items']);
                elseif iscell(items)
                    for k=1:length(items)
                        subPath = [path '/items/' num2str(k)];
                        items{k} = this.normalizeSchema_(rootSchema, items{k}, subPath);
                    end
                    schema('items') = items;
                end
            end

            if any(ismember({'number' 'integer'}, type))
                %if isfield(schema, 'enum') && iscell(schema.enum)
                %    if all(cellfun(@isnumeric, schema.enum))
                %        schema.enum = cell2mat(schema.enum);
                %    end
                %end
            end
            
        end
        
        function [ mergedSchema ] = mergeSchemas(this, rootSchema, schema)
            %MERGESCHEMAS Summary of this function goes here
            %   Detailed explanation goes here
            
            % Merge properties and required fields of all schemas.
            mergedSchema = containers.Map();
            mergedSchema('type') = 'object'; % TODO: Why not {'object'}?
            mergedProperties = containers.Map();
            mergedSchema('properties') = mergedProperties;
            mergedSchema('required') = {};
            allOf = schema('allOf');
            
            for k=1:length(allOf)
                subSchema = this.normalizeSchema_(rootSchema, allOf{k}, [path '/allOf']);
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

        function pType = validate(this, value, schema, path)

            function p = getBadPath(path, indices)
                isVec = length(indices) > 1;
                indices = find(indices);
                if isempty(indices)
                    p = [];
                elseif isVec
                    p = [path num2str(indices)];
                else
                    p = path;
                end
            end


            type = schema('type');
            pType = [];

            if isempty(type); return; end;

            if isempty(value)
                pType = type{1};
                return
            end

            n = numel(value);

            if ischar(value)
                if ismember('string', type)
                    pType = 'string';
                end
            elseif isstruct(value) || isa(value, 'Map')
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
                this.addError(path, sprintf('does not match type %s', strjoin(type, ' or ')), value);
                return
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
                            this.addError(path, sprintf('is missing required field %s', required{k}), value);
                        end
                    end
                end

                if JSON.getPath(schema, '/additionalProperties') == false
                    p = JSON.getPath(schema, '/properties', containers.Map()).keys();
                    s = s(~ismember(s, p));
                    pP = JSON.getPath(schema, '/patternProperties', containers.Map());
                    pp = pP.keys();
                    sFound = {};
                    for l=1:length(pp)
                        pattern = pp{l};
                        for k=1:length(s)
                            if ~isempty(regexp(s{k}, pattern))
                                sFound{end+1} = s{k};
                                break;
                            end
                        end
                    end

                    sNotFound = s(~ismember(s, sFound));
                    for k=1:length(sNotFound)
                        this.addError(path, 'contains additional property', sNotFound{k});
                    end
                end
            elseif ischar(value)
                if schema.isKey('pattern')
                    if isempty(regexp(value, schema('pattern')))
                        this.addError(path, sprintf('does not match pattern %s', schema('pattern')), value);
                    end
                end
                
                format = JSON.getPath(schema, '/format');
                
                if strcmp(format, 'date')
                    if isempty(regexp(value, '^\d{4}-\d{2}-\d{2}$'))
                        this.addError(path, 'is not a date', value);
                    end
                end
                
            elseif isnumeric(value)
                
                if strcmp(type, 'integer')
                    badPath = getBadPath(path, rem(value, 1));
                    if ~isempty(badPath)
                        this.addError(badPath, 'is not an integer', value);
                    end
                end
                
                if schema.isKey('minimum')
                    badPath = getBadPath(path, value < schema('minimum'));
                    if ~isempty(badPath)
                        this.addError(badPath, sprintf('is smaller than minimum %g', schema('minimum')), value);
                    end
                end
                
                if schema.isKey('maximum')
                    badPath = getBadPath(path, value > schema('maximum'));
                    if ~isempty(badPath)
                        this.addError(badPath, sprintf('is bigger than maximum %g', schema('maximum')), value);
                    end
                end
            end

            if schema.isKey('enum')
                if ~ismember(value, schema('enum'))
                    this.addError(path, 'is not contained in enumeration', value);
                end
            end

        end
        
    end
    
    methods (Static)
        
        function [value, errors] = parse(varargin)
            parser = JSON_Parser();
            
            try
                value = parser.parse_(varargin{:});
            catch e
                if 1 == regexp(e.identifier, '^JSON:', 'once')
                    value = [];
                    parser.addError([], e.message, [], e.identifier);
                else
                    for k=1:numel(e.stack)
                        e.stack(k)
                    end
                    rethrow(e);
                end
            end
            
            errors = parser.errors;
        end
        
        function [json, errors] = stringify(varargin)
            stringifier = JSON_Stringifier();
            
            try
                json = stringifier.stringify_(varargin{:});
            catch e
                if 1 == regexp(e.identifier, '^JSON:', 'once')
                    json = [];
                    stringifier.addError([], e.message, [], e.identifier);
                else
                    for k=1:numel(e.stack)
                        e.stack(k)
                    end
                    rethrow(e);
                end
            end
            
            errors = stringifier.errors;
        end
        
        function obj = getPath(obj, pointer, default)
            %GETPATH Returns the value under the pointer or empty if the pointer does not exist.
            % The pointer must be in JSON pointer syntax, so each component must be prefixed by /.
            %
            % Example:
            %    obj = containers.Map(); obj.foo = containers.Map(); obj.foo.bar = 13;
            %    getPath(obj, '/foo/bar') -> 13

            if isempty(pointer)
                if isempty(obj)
                    obj = default;
                end
                return;
            end

            if pointer(1) ~= '/'
                % TODO: Do not throw here
                error('Invalid pointer %s', pointer)
            end

            parts = strsplit(pointer, '/');

            for k = 2:length(parts)
                if isa(obj, 'Map') && obj.isKey(parts{k})
                    obj = obj(parts{k});
                else
                    if nargin >= 3
                        obj = default;
                    else
                        obj = [];
                    end
                    return;
                end
            end

        end

        function text = readFileToString(path, encoding )
            if JSON.isoct
                [fid, msg] = fopen(path, 'r');
            else
                [fid, msg] = fopen(path, 'r', 'l', encoding);
            end
            
            if fid == -1
                % TODO: Do not throw here
                error('Could not open %s: %s', path, msg);
            end
            
            text = fscanf(fid, '%c');
            fclose(fid);
        end
        
        function [s, err] = datenum2string(n)
            if ~isnumeric(n) || rem(n, 1)~=0
                s = n;
                err = 'must be an integer';
                return;
            else
                err = [];
                s = datestr(n, 'yyyy-mm-dd');
            end
        end
        
        function [s, err] = datetimenum2string(n)
            if ~isnumeric(n)
                s = n;
                err = 'must be a number';
                return;
            end
            d = javaObject('java.util.Date', round((n - 719529)*1000*60*60*24));
            d = javaObject('java.util.Date', d.getTime() + d.getTimezoneOffset()*60*1000);
            df = javaObject('java.text.SimpleDateFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX');
            s = char(df.format(d));
            err = [];
        end
        
        function [d, err] = datestring2num(s)
            % Parse date into a numerical date according MATLABs datenum().
            % The argument is returned if it is not a valid date.
            %
            % Example: '2016-01-26'
            
            m = regexp(s, '^(\d{4})-(\d{2})-(\d{2})$', 'tokens', 'once');
            
            if isempty(m)
                d = s;
                err = 'is not a valid date';
                return
            else
                d = datenum(str2double(m{1}),str2double(m{2}),str2double(m{3}));
                err = [];
            end
        end
        
        function [d, err] = datetimestring2num(s)
            % Parse ISO8601 date-time into a numerical date according MATLABs datenum() with respect to the default timezone.
            % Minutes and seconds are optional. Timezone offset is Z (meaning +00:00) or of the form +-02:00 or +-0200.
            % An error is returned if the argument is not a valid date-time.
            %
            % Example:
            %     JSON.datetimestring2num('2016-02-02T00:00:00+01:00')
            %     -> 736362 % Note: Only if default time zone is GMT!
            tokens = regexp(s, '^(.*T\d{2})(:\d{2})?(:\d{2})?(.*)$', 'tokens', 'once');
            
            if isempty(tokens)
                d = s;
                err = 'is not a valid date-time';
                return;
            end
            
            if length(tokens{end}) == 5
                tzf = 'Z'; % RFC 822 time zone -0800
            else
                tzf = 'XXX'; %  ISO 8601 time zone -08:00
            end
            
            fmts = {'', ':mm', ':mm:ss'};
            fmt = ['yyyy-MM-dd''T''HH' fmts{length(tokens)-1} tzf];
            
            df = javaObject('java.text.SimpleDateFormat', fmt);
            try
                d = df.parse(s);
            catch e
                d = s;
                err = 'is not a valid date-time';
                return;
            end
            
            % datenum('1970-01-01') == 719529
            d = (d.getTime()/1000/60 - d.getTimezoneOffset())/60/24 + 719529;
            err = [];
        end


        
    end
end


