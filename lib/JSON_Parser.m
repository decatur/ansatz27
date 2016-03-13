% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Parser < JSON
    %JSON_PARSER Validating JSON parser
    %   
    %    Usage:
    %       [value, errors] = JSON.parse('file:doc.json', 'file:schema.json')
    
    properties %(Access = private)
        pos
        len
        json
        esc
        index_esc
        len_esc
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
        
        function [value, errors] = parse_(this, json, rootschema)
            if nargin < 2 || ~ischar(json) || isempty(json)
                error('JSON:PARSE_JSON', 'JSON must be non-empty string');
            end

            this.errors = {};
            value = [];

            if nargin < 3
                rootschema = [];
            end

            if regexp(json, '^file:')
                this.json = JSON.readFileToString(regexprep(json, '^file:', ''), 'latin1');
            else
                this.json = json;
            end

            this.pos = 1;
            this.len = length(this.json);
            
            context = struct();
            context.path = '';;
            this.schemaURL = [];

            if ~isempty(rootschema) && ischar(rootschema) 
                [ context.schema, this.schemaURL ] = this.loadSchema( rootschema );
            elseif isstruct(rootschema)
                context.schema = rootschema;
            end

            if isfield(context, 'schema')
                try
                    context.schema = this.normalizeSchema(context.schema);
                catch e
                    this.addError(this.schemaURL, e.message, []);
                    errors = this.errors;
                    return
                end
            end
            
            % String delimiters and escape chars identified to improve speed:
            this.esc = find(this.json=='"' | this.json=='\' ); % comparable to: regexp(this.json, '["\\]');
            this.index_esc = 1;
            this.len_esc = length(this.esc);
            
            this.skip_whitespace();
            holder = StructHolder();

            this.parse_value(holder, [], 'value', context);
            this.skip_whitespace();
            if this.pos ~= this.len+1
                % Not all text was consumed.
                this.error_pos('Unexpected trailing text');
            end

            value = holder.value.value;
            
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
        
        
        
        function parse_object(this, holder, index, holderKey, context)
            
            this.parse_char('{');
            
            if strcmp(class(holder), 'StructArrayHolder')
                c = holder;
            else
                c = StructHolder();
            end
            
            if this.next_char() ~= '}'
                while 1
                    key = this.parseStr(struct());
                    key = this.valid_field(key);
                    this.parse_char(':');
                    this.parse_value(c, index, key, this.childContext(context, key));
                    if this.next_char() == '}'
                        break;
                    end
                    this.parse_char(',');
                end
            end
            this.parse_char('}');
            
            if ~strcmp(class(holder), 'StructArrayHolder')
                holder.setVal(index, holderKey, c.value);
            end
            
        end
        
        function parse_array(this, holder, context) % JSON array is written in row-major order
            this.parse_char('[');
            index = 0;
            
            if this.next_char() ~= ']'
                while 1
                    index = index + 1;
                    this.parse_value(holder, index, [], this.childContext(context, index));
                    if this.next_char() == ']'
                        break;
                    end
                    this.parse_char(',');
                end
            end
            
            this.parse_char(']');
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
        
        function str = parseStr(this, context)
            assert(this.json(this.pos) == '"');

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
        
        function parse_value(this, holder, index, key, context)
            schema = getPath(context, '/schema');
            
            switch(this.json(this.pos))
                case '"'
                    val = this.parseStr(context);
                case '['
                    items = getPath(schema, '/items');
                    itemType = getPath(items, '/type');

                    if ~isempty(itemType) && ismember('object', itemType) && getPath(items, '/additionalProperties') == false
                        c = StructArrayHolder();
                    else
                        c = CellArrayHolder();
                    end

                    this.parse_array(c, context);
                    val = c.value;

                    if strcmp(class(c), 'CellArrayHolder') && ~strcmp(class(holder), 'CellArrayHolder')
                        % End-of-line of a nested cell array. Try to convert to matrix.
                        val = cellToMat(val);
                    end
                case '{'
                    this.parse_object(holder, index, key, context);
                    val = holder.getVal(index, key);
                    if ~isempty(schema)
                        val = mergeDefaults(val, schema);
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
                validate(this, val, schema, context.path);
                format = getPath(schema, '/format');
                if this.formatters.isKey(format)
                    formatter = this.formatters(format);
                    val = formatter(val);
                end
            end

            holder.setVal(index, key, val);
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
        
        function validKey = valid_field(this, key)
            % Valid field names must begin with a letter, which may be
            % followed by any combination of letters, digits, and underscores.
            % Any invalid character will be replaced by '_', a leading invalid character will be replaced by 'x_'.
            if isempty(key)
                validKey = 'x____';
            else
                validKey = regexprep(key,'^[^A-Za-z]', 'x_');
                validKey = regexprep(validKey,'[^0-9A-Za-z_]', '_');
            end
        end % function valid_field
        
    end
end

