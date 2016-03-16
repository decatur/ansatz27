% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON < handle
    
    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    end
    
    properties %(Access = private)
        errors
        schemaURL
        formatters
        schemaCache
    end
    
    methods
        
        function this = JSON()
            this.formatters = containers.Map();
            this.schemaCache = containers.Map();
        end
        
        function [ schema, schemaURL ] = loadSchema(this, schema)
            schemaURL = [];
            
            if ischar(schema)
                if regexp(schema, '^file:')
                    schemaURL = regexprep(schema, '^file:', '');
                    schema = JSON.readFileToString(schemaURL, 'latin1');
                    %schema.url = schemaURL;
                end
                schema = JSON.parse(schema);
            else
                error('JSON:PARSE_SCHEMA', 'Schema must be of type char');
            end
        end
        
        %function rootDir = getRootDir(this)
        %    if isempty(this.schemaURL)
        %        rootDir = '.';
        %    else
        %        rootDir = fileparts(this.schemaURL);
        %    end
        %end
        
        function addError(this, path, msg, value, type)
            if nargin < 5
                type = 'JSON:SCHEMA_VALIDATION';
            end
            
            if isstruct(value)
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
                end
            elseif isnumeric(key)
                items = JSON.getPath(schema, '/items');
                if isstruct(items)
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
            while isfield(schema, 'x_ref')
                ref = schema.x_ref;
                
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
                    url = parts{1};
                    if this.schemaCache.isKey(url)
                        rootSchema = this.schemaCache.isKey(url);
                    else
                        fprintf(1, 'Loading schema %s\n', url);
                        rootSchema = JSON.parse(JSON.readFileToString( url, 'latin1' ));
                        %rootSchema.url = url;
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
            if ~isstruct(schema)
                return
            end
            
            if isfield(schema, 'x_ref')
                schema = this.resolveRef(rootSchema, schema, path);
            end
            
            if isfield(schema, 'allOf')
                schema = this.mergeSchemas(rootSchema, schema);
            end
            
            if ~isfield(schema, 'type') || isempty(schema.type)
                schema.type = {};
                return
            end
            
            type = schema.type;
            
            if ischar(type)
                type = {type};
            end
            
            schema.type = type;
            
            if isfield(schema, 'required') && ~iscell(schema.required)
                error('JSON:PARSE_SCHEMA', 'Invalid required at %s', path);
            end
            
            if ismember('object', type) && isfield(schema, 'properties') && ~isempty(schema.properties)
                props = schema.properties;
                pNames = fieldnames(props);
                for k=1:length(pNames)
                    subPath = [path '/properties/' pNames{k}];
                    schema.properties.(pNames{k}) = this.normalizeSchema_(rootSchema, props.(pNames{k}), subPath);
                end
            elseif ismember('array', type) && isfield(schema, 'items')
                if isstruct(schema.items)
                    schema.items = this.normalizeSchema_(rootSchema, schema.items, [path '/items']);
                elseif iscell(schema.items)
                    for k=1:length(schema.items)
                        subPath = [path '/items/' num2str(k)];
                        schema.items{k} = this.normalizeSchema_(rootSchema, schema.items{k}, subPath);
                    end
                end
            elseif any(ismember({'number' 'integer'}, type))
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
            mergedSchema = struct;
            mergedSchema.type = 'object';
            mergedSchema.properties = struct;
            mergedSchema.required = {};
            
            for k=1:length(schema.allOf)
                subSchema = this.normalizeSchema_(rootSchema, schema.allOf{k}, [path '/allOf']);
                
                keys = fieldnames(subSchema.properties);
                for l=1:length(keys)
                    key = keys{l};
                    mergedSchema.properties.(key) = subSchema.properties.(key);
                end
                
                if isfield(subSchema, 'required')
                    if isfield(mergedSchema, 'required')
                        mergedSchema.required = [mergedSchema.required subSchema.required];
                    else
                        mergedSchema.required = subSchema.required;
                    end
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
                if regexp(e.identifier, '^JSON:', 'once')
                    value = [];
                    parser.addError([], e.message, [], e.identifier);
                else
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
                if regexp(e.identifier, '^JSON:', 'once')
                    json = [];
                    stringifier.addError([], e.message, [], e.identifier);
                else
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
            %    obj = struct('foo', struct('bar', 13))
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
                if isfield(obj, parts{k})
                    obj = obj.(parts{k});
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


