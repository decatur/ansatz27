% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function pType = validate(this, value, schema, path)

type = schema.type;
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
elseif isstruct(value)
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
        if rem(value, 1) == 0 % integer value
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

if isstruct(value)
    if isfield(schema, 'required')
        for i=1:length(schema.required)
            if ~isfield(value, schema.required{i})
                this.addError(path, sprintf('is missing required field %s', schema.required{i}), value);
            end
        end
    end
elseif ischar(value)
    if isfield(schema, 'pattern')
        if isempty(regexp(value, schema.pattern))
            this.addError(path, sprintf('does not match pattern %s', schema.pattern), value);
        end
    end
    
    format = getPath(schema, 'format');
    
    if strcmp(format, 'date')
        if ~regexp(value, '^\d{4}-\d{2}-\d{2}$')
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
    
    if isfield(schema, 'minimum')
        badPath = getBadPath(path, value < schema.minimum);
        if ~isempty(badPath)
            this.addError(badPath, sprintf('is smaller than minimum %g', schema.minimum), value);
        end
    end
    
    if isfield(schema, 'maximum')
        badPath = getBadPath(path, value > schema.maximum);
        if ~isempty(badPath)
            this.addError(badPath, sprintf('is bigger than maximum %g', schema.maximum), value);
        end
    end
end

if isfield(schema, 'enum')
    if ~ismember(value, schema.enum)
        this.addError(path, 'is not contained in enumeration', value);
    end
end

end

