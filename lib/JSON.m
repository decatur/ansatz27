% COPYRIGHT Wolfgang Kuehn 2015-2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON < handle
    
    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
        %levelsToLog = { 'DEBUG', 'WARNING', 'INFO' };
        levelsToLog = { 'WARNING', 'INFO' };
    end
    
    properties %(Access = private)
        errors
        formatters
    end
    
    methods
        
        function this = JSON()
            this.formatters = containers.Map();
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
        
        function schema = loadSchema(url)
            schemaLoader = JSON_SchemaLoader();
            schema = schemaLoader.load( url );
        end
        
        function uri = resolveURIagainstLoadPath(uri)
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
            %    JSON.getPath(obj, '')                  % -> obj
            
            chain = {};
            
            if isempty(pointer)
                if isempty(obj)
                    obj = default;
                end
                return;
            end
            
            if pointer(1) ~= '/'
                % TODO: Do not throw here
                error('Invalid pointer syntax: %s', num2str(pointer));
            end
            
            tokens = strsplit(pointer, '/');
            
            for k = 2:length(tokens)
                chain{end+1} = obj;
                token = tokens{k};
                % '~' needs to be encoded as '~0' and '/' needs to be encoded as '~1'
                token = strrep(strrep(token, '~0', '~'), '~1', '/');
                
                if JSON.isaMap(obj)
                    if obj.isKey(token)
                        obj = obj(token);
                        continue;
                    end
                elseif iscell(obj)
                    if ~isempty(regexp(token, '^\d+$', 'once'))
                        l = str2double(token);
                        if l < length(obj) % This will also handle l is not a number
                            obj = obj{l+1};
                            continue;
                        end
                    end
                elseif isstruct(obj)
                    if isfield(obj, token)
                        obj = obj.(token);
                        continue;
                    end
                end
                
                if nargin >= 3
                    obj = default;
                else
                    obj = [];
                end
                break;
            end
            
        end
        
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
            err = [];
            
            %if ischar(d)
            %    s = d;
            %    return;
            %else
            if ~isa(d, 'datetime')
                err = ['is not a valid date: ' class(d)];
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
        end
        
    end
end


