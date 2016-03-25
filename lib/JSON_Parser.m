% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Parser < JSON
    %JSON_PARSER Validating JSON parser
    % See https://github.com/decatur/ansatz27
    
    properties %(Access = private)
        pos
        len
        json
        esc
        index_esc
        len_esc
        options
    end
    
    methods
        
        function this = JSON_Parser()
            %this@JSON();
            this.formatters('date') = @(x) JSON.datestring2num(x);
            this.formatters('date-time') = @(x) JSON.datetimestring2num(x);
        end
    
    end

    methods (Static)

    end
    
    methods
        
        function [value, errors] = parse_(this, json, rootschema, options)
            if nargin < 2 || ~ischar(json) || isempty(json)
                error('JSON:PARSE_JSON', 'JSON must be non-empty string');
            end

            this.errors = {};
            value = [];

            if nargin < 3
                rootschema = [];
            end

            if nargin < 4
                this.options = struct();
            else
                this.options = options;
            end

            if ~isfield(this.options, 'objectToStruct')
                this.options.objectToStruct = true;
            end

            if 1 == regexp(json, '^file:')
                this.json = JSON.readFileToString(regexprep(json, '^file:', ''), 'latin1');
            else
                this.json = json;
            end

            this.pos = 1;
            this.len = length(this.json);
            
            context = struct();
            context.path = '';

            if ~isempty(rootschema)
                if ischar(rootschema)
                    context.schema = this.loadSchema( rootschema );
                else
                    assert(isa(rootschema, 'Map'));
                    context.schema = rootschema;
                end
            end

            if isfield(context, 'schema')
                context.schema = this.normalizeSchema(context.schema);
            end
            
            % String delimiters and escape chars identified to improve speed:
            this.esc = find(this.json=='"' | this.json=='\' ); % comparable to: regexp(this.json, '["\\]');
            this.index_esc = 1;
            this.len_esc = length(this.esc);
            
            this.skip_whitespace();
            value = this.parse_value(context);
            this.skip_whitespace();

            if this.pos ~= this.len+1
                % Not all text was consumed.
                this.error_pos('Unexpected trailing text');
            end

            errors = this.errors;
        end
        
    end
    
    methods (Access=private)
        
        function child = childContext(this, context, key)
            child = struct();
            child.path = [context.path '/' num2str(key)];
            if ~isfield(context, 'schema')
                return
            end

            child.schema = this.getChildSchema(context.schema, key);
        end
        
        
        
        function val = parse_object(this, context)
            this.parse_char('{');

            if this.options.objectToStruct
                val = struct();
            else
                val = containers.Map();
            end
            
            if this.next_char() ~= '}'
                while 1
                    key = this.parseStr();
                    this.parse_char(':');
                    v = this.parse_value(this.childContext(context, key));
                    
                    if isstruct(val)
                        if 1 == regexp(key, '^[a-z][a-z0-9_]*$', 'ignorecase')
                            val.(key) = v;
                        end
                    else
                        val(key) = v;
                    end

                    if this.next_char() == '}'
                        break;
                    end
                    this.parse_char(',');
                end
            end
            this.parse_char('}');
            
        end
        
        function val = parse_array(this, context) % JSON array is written in row-major order
            this.parse_char('[');
            index = 0;

            schema = [];
            if isfield(context, 'schema')
                schema = context.schema;
            end

            items = JSON.getPath(schema, '/items');
            itemType = JSON.getPath(items, '/type'); % Note ~isempty(itemType) implies that items is an object, not a list.
            
            if this.options.objectToStruct && ~isempty(itemType) && isequal({'object'}, itemType) && strcmp(JSON.getPath(schema, '/format', 'structured-array'), 'structured-array')
                val = struct();
            else
                val = {};
            end
            
            if this.next_char() ~= ']'
                while 1
                    index = index + 1;
                    subContext = this.childContext(context, index);
                    subContext.isArray = true;
                    v = this.parse_value(subContext);
                    if isstruct(val)
                        % Note: Simply assigning val(index) = v will break if v and val have different fields!
                        names = fieldnames(v);
                        for k=1:length(names)
                            val(index).(names{k}) = v.(names{k});
                        end
                    else
                        val{index} = v;
                    end

                    if this.next_char() == ']'
                        break;
                    end
                    this.parse_char(',');
                end
            end
            
            this.parse_char(']');

            if iscell(val) && ~isfield(context, 'isArray')
                % End-of-line of a nested cell array. Try to convert to matrix.
                val = JSON_Parser.cellToMat(val);
            end
        end
        
        function vec = json1D2array(this, path)
            s = this.json(this.pos:end); % '[1, 2, 3]...'

            endPos = strchr(s, ']', 1);
            s = strtrim(s(2:endPos-1));
            s = strrep(s, 'null', 'NaN');

            [vec, COUNT, ERRMSG, POS] = sscanf(s, '%g,');

            if POS ~= length(s)+1
                vec = [];
                return 
            end

            this.pos = this.pos + endPos;
            this.skip_whitespace();
            vec = vec';
        end
        
        function parse_char(this, c)
            this.skip_whitespace();
            if this.pos > this.len || this.json(this.pos) ~= c
                this.error_pos(['Expected ' c]);
            else
                this.pos = this.pos + 1;
                this.skip_whitespace();
            end
        end
        
        function c = next_char(this)
            this.skip_whitespace();
            if this.pos > this.len
                c = [];
            else
                c = this.json(this.pos);
            end
        end
        
        function skip_whitespace(this)
            % TODO: rfc4627 only allows space, horizontal tab, line feed and carriage
            % return. isspace() also includes vertical tab, line feed and other
            % Unicode white space. So better use regexp with [\x20\x09\x0A\x0D].
            while this.pos <= this.len && isspace(this.json(this.pos))
                this.pos = this.pos + 1;
            end
        end
        
        function str = parseStr(this)
            if this.json(this.pos) ~= '"'
                this.error_pos('" expected');
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
                            this.error_pos('End of text reached right after escape character');
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
                                    this.error_pos('End of text reached in escaped unicode character');
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
            
            % Check for invalid chars.
            startIndices = regexp(str, '[\x0-\x1f]');
            if startIndices
                this.pos = startPos + startIndices(1);
                this.error_pos('Invalid char found in range #00-#1F');
            end

            if ~closed
                this.error_pos('Expected closing quote at end of text');
            end
        end
        
        function num = parse_number(this, context)
            [num, count, ~, nextIndex] = sscanf(this.json(this.pos: end), '%f', 1);
            
            if count ~= 1
                this.error_pos('Error reading number');
            end
            
            this.pos = this.pos + nextIndex - 1;
        end
        
        function b = parse_null(this)
            if this.pos+3 <= this.len && strcmp(this.json(this.pos:this.pos+3), 'null')
                b = true;
                this.pos = this.pos + 4;
            else
                b = false;
            end
        end
        
        function val = parse_value(this, context)
            schema = [];
            if isfield(context, 'schema')
                schema = context.schema;
            end

            switch(this.json(this.pos))
                case '"'
                    val = this.parseStr();
                case '['
                    val = this.parse_array(context);
                case '{'
                    val = this.parse_object(context);
                    if ~isempty(schema)
                        val = JSON_Parser.mergeDefaults(val, schema);
                    end
                case {'-','0','1','2','3','4','5','6','7','8','9'}
                    val = this.parse_number(context);
                case 't'
                    if this.pos+3 <= this.len && strcmp(this.json(this.pos:this.pos+3), 'true')
                        val = true;
                        this.pos = this.pos + 4;
                    else
                        this.error_pos('Token true expected');
                    end
                case 'f'
                    if this.pos+4 <= this.len && strcmp(this.json(this.pos:this.pos+4), 'false')
                        val = false;
                        this.pos = this.pos + 5;
                    else
                        this.error_pos('Token false expected');
                    end
                case 'n'
                    if this.parse_null()
                        val = NaN;
                    else
                        this.error_pos('Token null expected');
                    end
                otherwise
                    this.error_pos('Illegal token');
            end
            
            if ~isempty(schema)
                this.validate(val, schema, context.path);
                format = JSON.getPath(schema, '/format');
                if this.formatters.isKey(format)
                    formatter = this.formatters(format);
                    [val errMsg] = formatter(val);
                    if ~isempty(errMsg)
                        this.addError(context.path, errMsg, val);
                    end
                end
            end
        end
        
        function error_pos(this, msg)
            startPos = max(1, this.pos-15);
            endPos   = min(this.len, this.pos+15);

            part = this.json(startPos:endPos);
            index = min(length(part), this.pos-startPos+1);
            msg = [msg ' ' part(1:index) '^^^'];
            if index < length(part)
                msg = [msg part(index+1:end)];
            end

            error('JSON:PARSE_JSON', msg);
        end % function error_pos
        
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
                if length(cc) > 0
                    cc = cc{1};
                else
                    break;
                end
            end

            if length(dims) == 1
                dims = [1 dims];
            end

            m = inf(dims(:));

            hasLogical = false;
            hasNumeric = false;
            cc = c;
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
                m=c 
            elseif hasLogical
                l = true(dims(:));
                l(~m) = false;
                m = l;
            end

        end

        function mergedObject = mergeDefaults(object, schema)
            assert(isstruct(object));

            mergedObject = object;

            props = JSON.getPath(schema, '/properties');
            if ~isa(props, 'Map')
                return
            end

            propertyNames = props.keys();

            for i=1:length(propertyNames)
                name = propertyNames{i};
                property = props(name);
                if property.isKey('default') && ~isfield(mergedObject, name)
                    mergedObject.(name) = property('default');
                end
            end
        end

    end
end

