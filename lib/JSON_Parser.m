% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Parser < JSON
    %JSON_PARSER Validating JSON parser
    % See https://github.com/decatur/ansatz27
    
    properties %(Access = private)
        pos
        len
        lineCount
        posCurrentNewline
        json
        esc
        index_esc
        len_esc
        options
        schemaLoader
    end
    
    methods
        
        function this = JSON_Parser()
            %this@JSON();
            
            this.formatters('date') = @(s) JSON.datestring2datetime(s);
            this.formatters('date-time') = @(s) JSON.datetimestring2datetime(s);
        end
        
    end
    
    methods (Static)
        
    end
    
    methods
        
        function [value, errors] = parse(this, varargin)
            try
                value = this.parse_(varargin{:});
            catch e
                if ~isempty(regexp(e.identifier, '^JSON:', 'once'))
                    value = [];
                    this.addError([], e.message, [], e.identifier);
                else
                    for k=1:numel(e.stack)
                        e.stack(k)
                    end
                    rethrow(e);
                end
            end
            
            errors = this.errors;
        end
        
        function [value, errors] = parse_(this, json, rootschema, options)
            if nargin < 2 || ~ischar(json) || isempty(json)
                error('JSON:PARSE_JSON', 'JSON must be non-empty string');
            end
            
            this.errors = {};
            
            if nargin < 3
                rootschema = [];
            end
            
            if nargin < 4
                this.options = struct();
            else
                this.options = options;
            end
            
            if ~isfield(this.options, 'objectFormat')
                this.options.objectFormat = 'struct';
            end
            
            % If is does not look like JSON it must be a URI
            if isempty(regexp(json, '^\s*(\[|\{|"|true|false|null|\+?\-?\d)', 'ONCE'))
                uri = JSON.resolveURIagainstLoadPath(json);
                try
                    this.json = urlread(uri);
                catch e
                    error('JSON:PARSE', 'Could not read JSON from %s because: %s', uri, e.message);
                end
            else
                this.json = json;
            end
            
            this.pos = 1;
            this.len = length(this.json);
            this.lineCount = 1;
            this.posCurrentNewline = 0;
            
            this.schemaLoader = JSON_SchemaLoader();
            
            context = struct();
            context.pointer = '';
            if ischar(rootschema)
                context.schema = this.schemaLoader.load( rootschema );
            elseif this.isaMap(rootschema)
                context.schema = rootschema;
            else
                context.schema = [];
            end
            
            % String delimiters and escape chars identified to improve speed:
            this.esc = find(this.json=='"' | this.json=='\' ); % comparable to: regexp(this.json, '["\\]');
            this.index_esc = 1;
            this.len_esc = length(this.esc);
            
            this.skipWhitespace();
            value = this.parseValue(context, context.schema);
            this.skipWhitespace();
            
            if this.pos ~= this.len+1
                % Not all text was consumed.
                this.parseError('Unexpected trailing text at');
            end
            
            errors = this.errors;
        end
        
    end
    
    methods (Access=private)
        
        function child = getChildContext(this, context, key)
            child = struct();
            child.pointer = [context.pointer '/' num2str(key)];
        end
        
        function val = parseObject(this, context, schema)
            this.parseChar('{');
            
            objectFormat = JSON.getPath(schema, '/format', this.options.objectFormat);
            
            if strcmp(objectFormat, 'Map')
                val = containers.Map();
            else % default
                val = struct();
            end
            
            if this.nextChar() ~= '}'
                while 1
                    key = this.parseStr();
                    this.parseChar(':');
                    subContext = this.getChildContext(context, key);
                    subContext.schema = this.schemaLoader.getPropertySchema(schema, key);
                    
                    beginPos = this.pos;
                    v = this.parseValue(subContext, subContext.schema);
                    % TODO: Make sure this is really a default value
                    if isa(this, 'JSON_SchemaLoader') && strcmp(key, 'default')
                        % Retain the raw string for default values.
                        v = this.json(beginPos:this.pos-1);
                    end
                    
                    if isstruct(val)
                        if ~isempty(regexp(key, '^[a-z][a-z0-9_]*$', 'ignorecase'))
                            val.(key) = v;
                        end
                    else
                        val(key) = v;
                    end
                    
                    if this.nextChar() == '}'
                        break;
                    end
                    this.parseChar(',');
                    if this.json(this.pos) ~= '"'
                        % Common error, we better handle it here than with parseStr() above
                        this.parseError('tangling comma before');
                    end
                end
            end
            this.parseChar('}');
            
        end
        
        function val = parseArray(this, context, schema) % JSON array is written in row-major order
            this.parseChar('[');
            
            val = {};
            itemSchema = this.schemaLoader.getSubSchema(schema, '/items');
            if ~isempty(itemSchema)
                itemType = JSON.getPath(itemSchema, '/type');
                % Note ~isempty(itemType) implies that items is an object, not a list.
                if ~isempty(itemType) && isequal({'object'}, itemType) && strcmp(JSON.getPath(schema, '/format', 'structured-array'), 'structured-array')
                    val = struct();
                end
            end
            
            index = 0;
            
            if this.nextChar() ~= ']'
                while 1
                    subContext = this.getChildContext(context, index);
                    subContext.isArray = true;
                    if isempty(itemSchema)
                        subContext.schema = this.schemaLoader.getItemSchema(schema, index);
                    else
                        subContext.schema = itemSchema;
                    end
                    
                    index = index + 1;
                    v = this.parseValue(subContext, subContext.schema);
                    
                    if isstruct(val)
                        % Note: Simply assigning val(index) = v will break if v and val have different fields!
                        names = fieldnames(v);
                        for k=1:length(names)
                            val(index).(names{k}) = v.(names{k});
                        end
                    else
                        val{index} = v;
                    end
                    
                    if this.nextChar() == ']'
                        break;
                    end
                    this.parseChar(',');
                    if this.json(this.pos) == ']'
                        % Common error, we better handle it here than with parseStr() above
                        this.parseError('tangling comma before');
                    end
                end
            end
            
            this.parseChar(']');
            
            if iscell(val) && ~isfield(context, 'isArray')
                % End-of-line of a nested cell array. Try to convert to matrix.
                val = JSON_Parser.cellToMat(val);
            end
        end
        
        %         function vec = json1D2array(this, pointer)
        %             s = this.json(this.pos:end); % '[1, 2, 3]...'
        %
        %             endPos = strchr(s, ']', 1);
        %             s = strtrim(s(2:endPos-1));
        %             s = strrep(s, 'null', 'NaN');
        %
        %             [vec, COUNT, ERRMSG, POS] = sscanf(s, '%g,');
        %
        %             if POS ~= length(s)+1
        %                 vec = [];
        %                 return
        %             end
        %
        %             this.pos = this.pos + endPos;
        %             this.skipWhitespace();
        %             vec = vec';
        %         end
        
        function parseChar(this, c)
            this.skipWhitespace();
            if this.pos > this.len || this.json(this.pos) ~= c
                this.parseError(sprintf('Expected character %s at', c));
            else
                this.pos = this.pos + 1;
                this.skipWhitespace();
            end
        end
        
        function c = nextChar(this)
            this.skipWhitespace();
            if this.pos > this.len
                c = [];
            else
                c = this.json(this.pos);
            end
        end
        
        function skipWhitespace(this)
            % TODO: rfc4627 only allows space, horizontal tab, line feed and carriage
            % return. isspace() also includes vertical tab, line feed and other
            % Unicode white space. So better use regexp with [\x20\x09\x0A\x0D].
            while this.pos <= this.len && isspace(this.json(this.pos))
                if this.json(this.pos) == 10 % newline
                    this.lineCount = this.lineCount + 1;
                    this.posCurrentNewline = this.pos;
                end
                this.pos = this.pos + 1;
            end
        end
        
        function str = parseStr(this)
            if this.json(this.pos) ~= '"'
                this.parseError('expected character " at');
            end
            
            startPos = this.pos;
            this.pos = this.pos + 1;
            str = '';
            closed = false;
            
            while this.pos <= this.len
                while this.index_esc <= this.len_esc && this.esc(this.index_esc) < this.pos
                    this.index_esc = this.index_esc + 1;
                end
                
                if this.index_esc > this.len_esc
                    str = [str this.json(this.pos:this.len)];
                    this.pos = this.len + 1;
                    break;
                else
                    str = [str this.json(this.pos:this.esc(this.index_esc)-1)];
                    this.pos = this.esc(this.index_esc);
                end
                
                nstr = length(str);
                switch this.json(this.pos)
                    case '"'
                        closed = true;
                        this.pos = this.pos + 1;
                        break;
                    case '\'
                        if this.pos+1 > this.len
                            this.parseError('End of text reached right after escape character at');
                        end
                        this.pos = this.pos + 1;
                        switch this.json(this.pos)
                            case {'"' '\' '/'}
                                str(nstr+1) = this.json(this.pos);
                                this.pos = this.pos + 1;
                            case {'b' 'f' 'n' 'r' 't'}
                                str(nstr+1) = sprintf(['\' this.json(this.pos)]);
                                this.pos = this.pos + 1;
                            case 'u'
                                if this.pos+4 > this.len
                                    this.parseError('End of text reached in escaped unicode character at');
                                end
                                
                                if JSON.isoct
                                    str(nstr+(1:6)) = this.json(this.pos-1:this.pos+4);
                                else
                                    str(nstr+1) = native2unicode( [0 0 hex2dec(this.json(this.pos+1:this.pos+2)) hex2dec(this.json(this.pos+3:this.pos+4))], 'utf-32');
                                end
                                this.pos = this.pos + 5;
                        end
                    otherwise
                        assert(false, 'should never happen');
                        this.pos = this.pos + 1;
                end
            end
            
            % Now that we know where string ends, check original(!) string for invalid chars.
            startIndices = regexp(this.json(startPos+1:this.pos-2), '[\x0-\x1f]');
            if startIndices
                this.pos = startPos + startIndices(1);
                this.parseError('Invalid char found in range #00-#1F at');
            end
            
            if ~closed
                this.parseError('Expected closing quote at end of text at');
            end
        end
        
        function num = parseNumber(this)
            [num, count, ~, nextIndex] = sscanf(this.json(this.pos: end), '%f', 1);
            
            if count ~= 1
                this.parseError('Error reading number after');
            end
            
            this.pos = this.pos + nextIndex - 1;
        end
        
        function b = parseNull(this)
            if this.pos+3 <= this.len && strcmp(this.json(this.pos:this.pos+3), 'null')
                b = true;
                this.pos = this.pos + 4;
            else
                b = false;
            end
        end
        
        % TODO: Remove context.schema from caller
        function val = parseValue(this, context, schema)
            if isempty(schema) || ~schema.isKey('manyKeyword') || isequal(schema('manyKeyword'), 'allOf')
                val = this.parseValue_(context, schema);
            else
                val = this.parseMany(context, schema);
            end
        end
        
        function val = parseMany(this, context, schema)
            
            function other = copyState(state)
                if isstruct(state)
                    other = this;
                else
                    assert(isa(state, 'JSON_Parser'))
                    other = struct();
                end
                other.pos = state.pos;
                other.lineCount = state.lineCount;
                other.posCurrentNewline = state.posCurrentNewline;
                other.index_esc = state.index_esc;
            end
            
            manyKeyword = schema('manyKeyword');
            l = length(schema(manyKeyword));
            
            state = copyState(this);
            state.errorLength = length(this.errors);
            coersedVal = [];
            
            for k=1:l
                subSchema = this.schemaLoader.getSubSchema(schema, sprintf('/%s/%d', manyKeyword, k));
                
                val = this.parseValue_(context, subSchema);
                if length(this.errors) == state.errorLength
                    % There were no errors.
                    % First validating schema wins.
                    if isempty(coersedVal)
                        coersedVal = val;
                    end
                    
                    if isequal(manyKeyword, 'anyOf')
                        % anyOf can stop at first validating schema
                        break;
                    end
                end
                
                if k < l
                    % Reset state if there are more schemas to try.
                    this.errors = this.errors(1:state.errorLength);
                    copyState(state);
                end
            end
        end
        
        function val = parseValue_(this, context, schema)
            
            switch(this.json(this.pos))
                case '"'
                    val = this.parseStr();
                case '['
                    val = this.parseArray(context, schema);
                case '{'
                    val = this.parseObject(context, schema);
                    if ~isempty(schema)
                        val = this.mergeDefaults(val, schema);
                    end
                case {'-','0','1','2','3','4','5','6','7','8','9'}
                    val = this.parseNumber();
                case 't'
                    if this.pos+3 <= this.len && strcmp(this.json(this.pos:this.pos+3), 'true')
                        val = true;
                        this.pos = this.pos + 4;
                    else
                        this.parseError('Token true expected after');
                    end
                case 'f'
                    if this.pos+4 <= this.len && strcmp(this.json(this.pos:this.pos+4), 'false')
                        val = false;
                        this.pos = this.pos + 5;
                    else
                        this.parseError('Token false expected after');
                    end
                case 'n'
                    if this.parseNull()
                        val = NaN;
                    else
                        this.parseError('Token null expected before');
                    end
                otherwise
                    this.parseError('Illegal token at');
            end
            
            if ~isempty(schema)
                pType = this.inferePrimitiveType(val, schema, context.pointer);
                if ~isempty(pType)
                    % TODO: There must always be a pType
                    this.validate(val, pType, schema, context.pointer);
                end
                format = JSON.getPath(schema, '/format');
                if this.formatters.isKey(format)
                    formatter = this.formatters(format);
                    [val, errMsg] = formatter(val);
                    if ~isempty(errMsg)
                        this.addError(context.pointer, errMsg, val);
                    end
                end
            end
        end
        
        function mergedObject = mergeDefaults(this, object, schema)
            assert(isstruct(object) || JSON.isaMap(object));
            
            if isstruct(object)
                s = fieldnames(object);
            else
                s = object.keys();
            end
            
            mergedObject = object;
            props = JSON.getPath(schema, '/properties');
            if ~JSON.isaMap(props)
                return
            end
            
            propertyNames = props.keys();
            
            for i=1:length(propertyNames)
                name = propertyNames{i};
                property = this.schemaLoader.getPropertySchema(schema, name);
                if ~isempty(property) && property.isKey('default') && ~ismember(name, s)
                    if isstruct(mergedObject)
                        mergedObject.(name) = property('default');
                    else
                        mergedObject(name) = property('default');
                    end
                end
            end
        end
        
        function parseError(this, msg)
            error('JSON:PARSE_JSON', '%s line %i, column %i', ...
                msg, this.lineCount, this.pos-this.posCurrentNewline);
        end
        
    end
    
    methods (Static)
        
        function m=cellToMat(c)
            
            assert(iscell(c));
            
            if isempty(c)
                m = [];
                return;
            end
            
            cc = c;
            dims = [];
            
            while iscell(cc)
                dims = [dims length(cc)];
                if ~isempty(cc)
                    cc = cc{1};
                else
                    break;
                end
            end
            
            if length(dims) == 1
                dims = [1 dims];
            end
            
            m = inf(dims(:)');
            
            hasLogical = false;
            hasNumeric = false;
            stack = {c};
            ind = {1};
            
            while true
                k = ind{end};
                if k<=length(stack{end})
                    cc = stack{end}{k};
                    if iscell(cc)
                        stack{end+1} = cc;
                        ind{end+1} = 1;
                    elseif isnumeric(cc) || islogical(cc)
                        if isempty(cc)
                            cc = nan;
                        end
                        
                        if islogical(cc)
                            hasLogical = true;
                        else
                            hasNumeric = true;
                        end
                        
                        indx = struct('type', '()');
                        indx.subs = ind;
                        m = subsasgn(m, indx, cc);
                        ind{end} = 1+ind{end};
                    else
                        m = c;
                        return;
                    end
                else
                    stack = stack(1:end-1);
                    if isempty(stack)
                        break;
                    end
                    ind = ind(1:end-1);
                    ind{end} = 1 + ind{end};
                end
            end
            
            if any(isinf(m(:)))
                m = c;
            elseif hasNumeric && hasLogical
                m = c;
            elseif hasLogical
                l = true(dims(:)');
                l(~m) = false;
                m = l;
            end
            
        end
        
    end % static methods
end

