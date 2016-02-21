% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Stringifier < JSON_Handler
    %JSON_PARSER Validating JSON stringifier
    %
    %    Usage:
    %       [value, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json', 4)
    
    properties (Access = private)
        nl
        sepPostfix
        indent
    end
    
    methods
        function this = JSON_Stringifier()
            %this@JSON_Handler();
            this.formatters('date') = @(x) JSON_Handler.datenum2string(x);
            this.formatters('date-time') = @(x) JSON_Handler.datetimenum2string(x);
        end
    end

    methods (Static)
        function [json, errors] = stringify(varargin)
            stringifier = JSON_Stringifier();
            [json, errors] = stringifier.stringify_(varargin{:});
        end
    end
    
    methods
        
        function [json, errors] = stringify_(this, value, rootschema, space)
            %json=JSON_stringify(value, space) converts an object to JSON
            %   notation representing it.
            %
            % See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify
            % The JSON format and much more can be found at http://json.org.
            %
            % Arguments
            %   value: The value to convert to a JSON string.
            %   rootschema: (Optional) A JSON schema.
            %   space: Causes the resulting string to be pretty-printed.
            %
            % Returns
            %   json: A string in the JSON format (see http://json.org)
            %
            % Examples
            %   JSON_stringify(struct('foo', 'Hello', 'bar', 1))
            %   JSON_stringify(rand(10))
            %   JSON_stringify(struct('foo', 'Hello', 'password', 'keep_me_secret')
            %
            %   schema = JSON_parse('{"type": "object", "properties": { "bar": { "type": "numeric", "format": "matrix" }}}');
            %   JSON_stringify(struct('bar', 1))
            %
            % Authors:
            %   Wolfgang Kuehn 2015, 2016
            %   Qianqian Fang 2011-09-09
            
            if nargin < 2
                json = [];
                errors = [];
                return;
            end

            if nargin < 3
                rootschema = [];
            end

            if nargin < 4
                % Default is 4 spaces indentation per level.
                space = 4;
            end

            this.schemaURL = [];

            if ischar(rootschema)
                [ rootschema, this.schemaURL ] = this.loadSchema( rootschema );
            end

            if ~isempty(rootschema)
                rootschema = this.normalizeSchema(rootschema);
            end
            
            this.errors = {};
            context = struct();
            
            this.indent = '';
            
            if isnumeric(space)
                this.indent = repmat(' ', 1, space);
            elseif ischar(space)
                this.indent = space;
            end

            if isempty(this.indent)
                this.nl = '';
                this.sepPostfix = '';
            else
                this.nl = sprintf('\r\n');
                this.sepPostfix = ' ';
            end

            context.gap = '';
            context.path = '/';
            
            json = this.value2json(value, context, rootschema);
            errors = this.errors;
            assert(~isempty(rootschema) || isempty(errors));
        end
        
    end
    
    methods (Access=private)
        
        function schema = childSchema(this, schema, key)
            if ~isempty(schema) && strcmp(schema.type, 'object') && isfield(schema, 'properties') && isfield(schema.properties, key)
                schema = schema.properties.(key);
            else
                schema = [];
            end
        end
        
        function pType = validate_(this, value, schema, path)
            pType = validate(this, value, schema, path);
        end
        
        
        function json = value2json(this, value, context, schema)
            if isempty(schema)
                type = {};
            else
                type = schema.type;
            end

            json = [];
            pType = [];

            if ~isempty(type)
                %[json, pType] = str_(this, value, context, schema);

                pType = this.validate_(value, schema, context.path);
                isarray = strcmp(pType, 'array');
                
                if ~isempty(json)
                    return;
                end
            else
                isarray = (numel(value) > 1);
            end

            if ischar(value)
                json = this.quote(value);
            elseif iscell(value)
                json = this.objArray2json(value, context, getPath(schema, 'items'));
            elseif isstruct(value)
                if isarray
                    json = this.objArray2json(value, context, getPath(schema, 'items'));
                else
                    json = this.struct2json(value, context, schema);
                end
            %elseif islogical(value) % Note that logical is also numeric so it must preceed numeric treatment
            %    json = mat2str(value);
            elseif isnumeric(value) || islogical(value) % Note empty [] is numeric
                if isnumeric(value)
                    value = this.normalize2nan(value);
                end

                if isarray
                    json = this.foo(value, context, schema);
                    %json = this.matrix2json(value, context, schema);
                elseif isempty(value)
                    json = 'null';
                else
                    json = this.nan2null(num2str(value, this.numberFormat(schema)));
                end

                if islogical(value)
                    json = strrep(json, '1', 'true');
                    json = strrep(json, '0', 'false');
                end
            end
        end
        
        function fmt = numberFormat(this, schema)
            if isfield(schema, 'fixedPrecision') && isnumeric(schema.fixedPrecision)
                % Note: '%.nf' means n number of digits to the right of the decimal point
                fmt = sprintf('%%.%if', fix(schema.fixedPrecision));
            else
                fmt = '%.11g';
            end
            
        end
        
        function txt = struct2json(this, value, context, schema)
            assert(isstruct(value), 'input is not a struct');
            
            txt = sprintf('{%s', this.nl);
            mind = context.gap;
            context.gap = [context.gap this.indent];
            path = context.path;
            
            names = fieldnames(value);
            l = length(names);
            isFirstItem = true;
            
            for i=1:l
                key = names{i};
                context.path = [path key '/'];
                item_str = this.value2json(value.(key), context, this.childSchema(schema, key));
                if isempty(item_str)
                    continue;
                end
                
                if ~isFirstItem
                    txt = sprintf('%s,%s', txt, this.nl);
                end
                
                isFirstItem = false;
                txt = sprintf('%s%s"%s":%s%s', txt, context.gap, key, this.sepPostfix, item_str);
            end
            
            if ~isempty(this.indent)
                txt = sprintf('%s%s%s}', txt, this.nl, mind);
            else
                txt = sprintf('%s}', txt);
            end
        end
        
        function txt = objArray2json(this, value, context, itemsSchema)
            assert(iscell(value) || isstruct(value));

            txt = sprintf('[%s', this.nl);
            mind = context.gap;
            context.gap = [context.gap this.indent];
            path = context.path;
            l = length(value);
            
            for i=1:l

                if iscell(itemsSchema)
                    schema = itemsSchema{i};
                else
                    schema = itemsSchema;
                end

                if isstruct(value)
                    item = value(i);
                else
                    item = value{i};
                end
                
                context.path = [path num2str(i) '/'];
                item_str = this.value2json(item, context, schema);
                
                if isempty(item_str)
                    item_str = 'null';
                end
                
                txt = sprintf('%s%s%s', txt, context.gap, item_str);
                
                if i<l
                    txt = sprintf('%s,%s', txt, this.nl);
                end
            end
            
            if ~isempty(this.indent)
                txt = sprintf('%s%s%s]', txt, this.nl, mind);
            else
                txt = sprintf('%s]', txt);
            end
        end
        
        % Replace complex numbers by NaNs.
        function number = normalize2nan(this, number)
            % JSON has no notion of those special IEEE 754 numbers.
            number(number~=conj(number) | isinf(number)) = NaN;
        end
        
        function txt = nan2null(this, txt)
            txt = regexprep(txt, 'NaN', 'null');
        end
        
        function txt = vector2json(this, row, context, schema)
            
            gap = sprintf('%s%s', context.gap, this.indent);
            
            fmt = [this.numberFormat(schema) ', '];
            
            txt = sprintf(fmt, row);
            % Remove last separator
            txt(end-1:end) = '';
            
            txt = sprintf('[%s%s%s%s%s]', this.nl, gap, txt, this.nl, context.gap);
            
        end
        
        function txt = foo(this, value, context, schema)
            %assert(ismatrix(value));
            s = size(value);
            
            itemsSchema = getPath(schema, 'items');

            mindGap = context.gap;  
            context.gap = [context.gap this.indent];
            
            txt = sprintf('[%s%s', this.nl, context.gap);
            sep = '';

            if s(1) > 1
                for k=1:s(1)
                    row = value(k, :);
                    txt = sprintf('%s%s%s', txt, sep, this.value2json(row, context, itemsSchema));
                    sep = ',';
                end
            else
                for k=1:s(2)
                    row = value(k);
                    txt = sprintf('%s%s%s', txt, sep, this.value2json(row, context, itemsSchema));
                    sep = ',';
                end
            end
            
            txt = sprintf('%s%s%s]', txt, this.nl, mindGap);
        end

        function txt = quote(this, value)
            assert(ischar(value), 'input is not a string');
            
            txt = strrep(value, '\', '\\');
            txt = strrep(txt, '"', '\"');
            txt = strrep(txt, sprintf('\n'), '\n');
            txt = strrep(txt, sprintf('\r'), '\r');
            txt = strrep(txt, sprintf('\t'), '\t');
            
            txt = ['"', txt ,'"'];
        end
        
    end
    
end