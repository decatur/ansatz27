% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Stringifier < JSON
    %JSON_Stringifier Validating JSON stringifier
    %
    %    Usage:
    %       [value, errors] = JSON.stringify(obj, 'file:schema.json', 4)
    
    properties (Access = private)
        nl
        sepPostfix
        indent
    end
    
    methods
        function this = JSON_Stringifier()
            %this@JSON();
            this.formatters('date')      = @(d) JSON.datetime2string(d);
            this.formatters('date-time') = @(d) JSON.datetime2string(d);
        end
    end

    methods (Static)
    end
    
    methods
        
        function [json, errors] = stringify(this, varargin)
            try
                json = this.stringify_(varargin{:});
            catch e
                if ~isempty(regexp(e.identifier, '^JSON:', 'once'))
                    json = [];
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
        
        function [json, errors] = stringify_(this, value, rootschema, space)
            %json=JSON_stringify(value, space) converts an object to JSON
            %   notation representing it.
            %
            % Arguments
            %   value: The value to convert to a JSON string.
            %   rootschema: (Optional) A JSON schema.
            %   space: Causes the resulting string to be pretty-printed.
            %
            % Returns
            %   json: A string in the JSON format (see http://json.org)
            %
            % Authors:
            %   Wolfgang Kuehn 2015, 2016
            %   Qianqian Fang 2011-09-09
            
            json = [];

            if nargin < 2
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

            this.errors = {};
            rootschema = this.loadSchema( rootschema );
            
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
            context.pointer = '';
            
            json = this.stringifyValue(value, context, rootschema);
            errors = this.errors;
            assert(~isempty(rootschema) || isempty(errors));
        end
        
    end
    
    methods (Access=private)
        
        function json = stringifyValue(this, value, context, schema)

            if isempty(schema) || ~schema.isKey('manyKeyword') || isequal(schema('manyKeyword'), 'allOf')
                json = this.stringifyValue_(value, context, schema);
            else
                json = this.stringifyMany(value, context, schema);
            end
        end

        function coercedJson = stringifyMany(this, value, context, schema)
            manyKeyword = schema('manyKeyword');
            l = length(schema(manyKeyword));

            state = struct();
            state.errorLength = length(this.errors);
            coercedJson = [];

            for k=1:l
                subSchema = this.getSubSchema(schema, sprintf('/%s/%d', manyKeyword, k));
                json = this.stringifyValue_(value, context, subSchema);
                if length(this.errors) == state.errorLength
                    % First validation schema wins.
                    if isempty(coercedJson)
                        coercedJson = json;
                    end

                    if isequal(manyKeyword, 'anyOf')
                        break;
                    end
                elseif k < l
                    % Reset state
                    this.errors = this.errors(1:state.errorLength);
                end
            end
        end

        function json = stringifyValue_(this, value, context, schema)
            if isnumeric(value)
                value = this.normalize2nan(value);
            end

            format = JSON.getPath(schema, '/format');
            if this.formatters.isKey(format)
                formatter = this.formatters(format);
                [value, errMsg] = formatter(value);
                if ~isempty(errMsg)
                    this.addError(context.pointer, errMsg, value);
                end
            end


            if isempty(schema)
                type = {};
            else
                assert(JSON.isaMap(schema));
                type = schema('type');
            end

            json = [];
            pType = [];

            if ~isempty(type)
                pType = this.inferePrimitiveType(value, schema, context.pointer);
                isarray = strcmp(pType, 'array');
                
                if ~isempty(json)
                    return;
                end
            else
                isarray = (numel(value) > 1);
            end

            if ischar(value)
                json = this.string2json(value);
            elseif iscell(value)
                json = this.objArray2json(value, context, schema);
            elseif isstruct(value) || JSON.isaMap(value)
                if isarray
                    json = this.objArray2json(value, context, schema);
                else
                    json = this.object2json(value, context, schema);
                end
            elseif isnumeric(value) || islogical(value) % Note empty [] is numeric
                if isarray
                    if isrow(value) || isempty(value)
                        % A row vector, possibly empty.
                        json = this.row2json(value, context, schema);
                    else
                        json = this.tensor2json(value, context, schema);
                    end
                elseif isempty(value)
                    json = 'null';
                else
                    % TODO: Assert that value has only one element!
                    json = this.nan2null(num2str(value, this.numberFormat(schema)));
                end

                if islogical(value)
                    json = strrep(json, '1', 'true');
                    json = strrep(json, '0', 'false');
                end
            end

            if ~isempty(pType)
                this.validate(value, pType, schema, context.pointer);
            end
        end
        
        function fmt = numberFormat(this, schema)
            if JSON.isaMap(schema) && schema.isKey('fixedPrecision') && isnumeric(schema('fixedPrecision'))
                % Note: '%.nf' means n number of digits to the right of the decimal point
                fmt = sprintf('%%.%if', fix(schema('fixedPrecision')));
            else
                fmt = '%.11g';
            end
            
        end
        
        function txt = object2json(this, value, context, schema)
            assert(isstruct(value) || JSON.isaMap(value));
            
            txt = sprintf('{%s', this.nl);
            mind = context.gap;
            context.gap = [context.gap this.indent];
            pointer = context.pointer;
            
            if isstruct(value)
                names = fieldnames(value);
            else
                names = value.keys();
            end

            isFirstItem = true;
            
            for k=1:length(names)
                key = names{k};
                context.pointer = [pointer '/' key];

                if isstruct(value)
                    v = value.(key);
                else
                    v = value(key);
                end

                item_str = this.stringifyValue(v, context, this.getPropertySchema(schema, key));
                if isempty(item_str) || strcmp(item_str, 'null') % TODO: Can it be empty?
                    continue;
                end
                
                if isFirstItem
                    isFirstItem = false;
                else
                    txt = sprintf('%s,%s', txt, this.nl);
                end
                
                txt = sprintf('%s%s"%s":%s%s', txt, context.gap, key, this.sepPostfix, item_str);
            end
            
            if ~isempty(this.indent)
                txt = sprintf('%s%s%s}', txt, this.nl, mind);
            else
                txt = sprintf('%s}', txt);
            end
        end
        
        function txt = objArray2json(this, value, context, schema)
            assert(iscell(value) || isstruct(value));

            txt = sprintf('[%s', this.nl);
            itemContext = context;
            itemContext.gap = [context.gap this.indent];
            l = length(value);
            
            for k=1:l
                itemSchema = this.getItemSchema(schema, k-1);

                if isstruct(value)
                    item = value(k);
                else
                    item = value{k};
                end
                
                itemContext.pointer = [context.pointer '/' num2str(k-1)];
                item_str = this.stringifyValue(item, itemContext, itemSchema);
                
                if isempty(item_str)
                    item_str = 'null';
                end
                
                txt = sprintf('%s%s%s', txt, itemContext.gap, item_str);
                
                if k<l
                    txt = sprintf('%s,%s', txt, this.nl);
                end
            end
            
            if ~isempty(this.indent)
                txt = sprintf('%s%s%s]', txt, this.nl, context.gap);
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
            txt = strrep(txt, 'NaN', 'null');
        end
        
        function txt = tensor2json(this, tensor, context, schema)
            % Loop over the first dimension of a tensor and call stringifyValue on tensor(k, :, ...)
            s = size(tensor);
            assert(s(1) > 0);
            
            oneItemSchema = JSON.getPath(schema, '/items');
            if isempty(oneItemSchema)
                % Make sure a column vector such as [1;2] is generated as [[1],[2]].
                oneItemSchema = containers.Map();
                oneItemSchema('type') = { 'array' };
            elseif JSON.isaMap(oneItemSchema)
                oneItemSchema = this.getSubSchema(schema, '/items');
            else
                oneItemSchema = [];
            end

            itemContext = context;
            itemContext.gap = [context.gap this.indent];

            txt = sprintf('[%s%s', this.nl, itemContext.gap);
            sep = '';

            indx = struct('type', '()');

            for k=1:s(1)
                % We have to use subsref because tensor may have any dimension >= 2.
                % Example tensor=[1 2;3 4]
                %   cat(1, { 2 }, cellstr(repmat(':', ndims(tensor)-1, 1))) -> { 2 ':' }
                %   squeeze(subsref(tensor, indx)) -> [3 4]
                indx.subs = cat(1, { k }, cellstr(repmat(':', ndims(tensor)-1, 1)));
                m = squeeze(subsref(tensor, indx));

                if isempty(oneItemSchema)
                    itemSchema = this.getItemSchema(schema, k-1);
                else
                    itemSchema = oneItemSchema;
                end

                itemContext.pointer = [context.pointer '/' num2str(k-1)];

                txt = sprintf('%s%s%s', txt, sep, this.stringifyValue(m, itemContext, itemSchema));
                sep = ',';
            end

            txt = sprintf('%s%s%s]', txt, this.nl, context.gap);
        end

        function txt = row2json(this, row, context, schema)
            assert(isrow(row) || isempty(row))
            
            %items = JSON.getPath(schema, '/items');

            itemContext = context;
            itemContext.gap = [context.gap this.indent];
            
            txt = sprintf('[%s%s', this.nl, itemContext.gap);
            sep = '';


            for k=1:numel(row)
                itemSchema = this.getItemSchema(schema, k-1);
                itemContext.pointer = [context.pointer '/' num2str(k-1)];

                txt = sprintf('%s%s%s', txt, sep, this.stringifyValue(row(k), itemContext, itemSchema));
                sep = ',';
            end

            txt = sprintf('%s%s%s]', txt, this.nl, context.gap);
        end

        function txt = string2json(this, s)
            assert(ischar(s), 'input is not a string');
            
            txt = strrep(s, '\', '\\');
            txt = strrep(txt, '"', '\"');
            txt = strrep(txt, sprintf('\n'), '\n');
            txt = strrep(txt, sprintf('\r'), '\r');
            txt = strrep(txt, sprintf('\t'), '\t');
            
            txt = ['"', txt ,'"'];
        end
        
    end
    
end