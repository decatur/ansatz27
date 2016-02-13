% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Stringifier < JSON_Handler
    %JSON_PARSER Validating JSON stringifier
    %
    %    Usage:
    %       [value, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json', 4)
    
    properties (Access = private)
        nl
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
            else
                this.nl = sprintf('\r\n');
            end

            context.gap = '';
            context.path = '/';
            
            json = this.str(value, context, rootschema);
            errors = this.errors;
        end
        
    end
    
    methods (Access=private)
        
        function schema = childSchema(this, schema, key)
            if isfield(schema, 'type') && strcmp(schema.type, 'object') && isfield(schema, 'properties') && isfield(schema.properties, key)
                schema = schema.properties.(key);
            else
                schema = [];
            end
        end
        
        function newValue = validate_(this, value, actType, schema, path)
            newValue = validate(this, value, actType, schema, path);
        end
        
        function json = str(this, value, context, schema)
            json = [];
            n = numel(value);
            
            if isempty(schema)
                if ischar(value)
                    json = this.quote(value);
                elseif iscell(value)
                    json = this.objArray2json(value, context, []);
                elseif n == 0
                    json = 'null';
                elseif n == 1
                    if isnumeric(value)
                        json = this.nan2null(num2str(this.normalize2nan(value), this.numberFormat([])));
                    elseif islogical(value)
                        json = mat2str(value);
                    elseif isstruct(value)
                        json = this.struct2json(value, context, []);
                    end
                else % n > 1
                    if isnumeric(value)
                        json = this.matrix2json(value, context, []);
                    else
                        json = this.objArray2json(value, context, []);
                    end
                end
            else % ~isempty(schema)

                type = getPath(schema, 'type');
                format = getPath(schema, 'format');

                if this.formatters.isKey(format)
                    formatter = this.formatters(format);
                    value = formatter(value);
                end
    
                if isempty(type)
                    this.addErrors(sprintf('Missing schema type for path %s', context.path));
                elseif isnumeric(value) || islogical(value)
                    if strcmp(type, 'array')
                        value = this.validate_(value, 'array', schema, context.path);
                        type = getPath(schema, 'items/type');
                        if ~isempty(type)
                            if strcmp(type, 'number') || strcmp(type, 'integer') 
                              json = this.matrix2json(value, context, schema);
                            elseif strcmp(type, 'array') && strcmp(getPath(schema, 'items/items/type'), 'number')
                                json = this.matrix2json(value, context, schema.items.items);
                            elseif strcmp(type, 'object')
                                json = this.objArray2json(value, context, getPath(schema, 'items'));
                            end
                        end
                    else
                        if n == 1
                            value = this.validate_(value, type, schema, context.path);
                            if strcmp(type, 'integer')
                                json = num2str(fix(this.normalize2nan(value)), '%i');
                            else % number
                                json = this.nan2null(num2str(this.normalize2nan(value), this.numberFormat(schema)));
                            end
                        elseif n == 0
                            json = 'null';
                        else
                            this.addErrors(sprintf('At %s, value has more than one element', path));
                        end
                    end
                elseif isstruct(value)
                    if strcmp(type, 'array')
                        value = this.validate_(value, 'array', schema, context.path);
                        json = this.objArray2json(value, context, getPath(schema, 'items'));
                    else
                        if n == 1
                            value = this.validate_(value, type, schema, context.path);
                            json = this.struct2json(value, context, schema);
                        elseif n == 0
                            json = 'null';
                        else
                            this.addErrors(sprintf('At %s, value has more than one element', path));
                        end
                    end
                elseif iscell(value)
                    value = this.validate_(value, 'array', schema, context.path);
                    json = this.objArray2json(value, context, getPath(schema, 'items'));
                elseif ischar(value)
                    if strcmp(type, 'array')
                        value = this.validate_(value, 'array', schema, context.path);
                        json = this.objArray2json(value, context, getPath(schema, 'items'));
                    else
                        value = this.validate_(value, 'string', schema, context.path);
                        json = this.quote(value);
                    end
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
                item_str = this.str(value.(key), context, this.childSchema(schema, key));
                if isempty(item_str)
                    continue;
                end
                
                if ~isFirstItem
                    txt = sprintf('%s,%s', txt, this.nl);
                end
                
                isFirstItem = false;
                txt = sprintf('%s%s"%s": %s', txt, context.gap, key, item_str);
            end
            
            if ~isempty(this.indent)
                txt = sprintf('%s%s%s}', txt, this.nl, mind);
            else
                txt = sprintf('%s}', txt);
            end
        end
        
        % This is a copy of struct2json with obvious modifications.
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
                item_str = this.str(item, context, schema);
                
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
        
        function txt = matrix2D2json(this, value, context, schema)
            
            gap = sprintf('%s%s', context.gap, this.indent);
            
            if ~isempty(this.indent)
                sep = ', ';
            else
                sep = ',';
            end

            fmt = this.numberFormat(schema);
            
            colCount = size(value, 2);
            fmt = sprintf(' [%s%s%s%s%s%s%s],', this.nl, gap, this.indent, repmat([fmt sep], 1, colCount-1), fmt, this.nl, gap);
            nd = ndims (value);
            txt = sprintf (fmt, permute (value, [2, 1, 3:nd]));
            txt(1) = '';
            txt(end) = '';
            txt = sprintf('[%s%s%s%s%s]', this.nl, gap, txt, this.nl, context.gap);
            
        end
        
        function txt = matrix2json(this, value, context, itemSchema)
            
            if ~isnumeric(value)
                txt = [];
                return;
            end
            
            value = this.normalize2nan(value);
            
            s = size(value);
            mindGap = context.gap;
            
            if length(s) > 2
                context.gap = [context.gap this.indent];
                txt = sprintf('[%s%s', this.nl, context.gap);
                sep = '';
                for i=1:s(1)
                    m = value(i, :);
                    m = reshape(m, s(2), s(end));
                    txt = sprintf('%s%s%s%s', txt, sep, this.matrix2json(m, context, itemSchema));
                    sep = ',';
                end
                txt = sprintf('%s%s%s]', txt, this.nl, mindGap);
            elseif s(1) == 1
                txt = this.vector2json(value, context, itemSchema);
            elseif s(2) == 1
                txt = this.vector2json(value', context, itemSchema);
            else
                txt = this.matrix2D2json(value, context, itemSchema);
            end
            
            txt = this.nan2null(txt);
            
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


