% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function newValue = validate(this, value, actType, schema, path)

newValue = value;

if ~isfield(schema, 'type')
    this.addError(path, 'has no type specified', value);
    return
end

type = schema.type;

if strcmp(actType, 'string')
    if ~strcmp(type, 'string')
        this.addError(path, sprintf('does not match type %s', type), value);
        return;
    end
elseif strcmp(actType, 'object') || strcmp(actType, 'array')
    if ~ismember(actType, type)
        this.addError(path, sprintf('does not match type %s', type), value);
        return;
    end
elseif strcmp(actType, 'number')
    if ~strcmp(type, 'number') && ~strcmp(type, 'integer')
        this.addError(path, sprintf('does not match type %s', type), value);
        return;
    end
elseif strcmp(actType, 'boolean')
    booleanStrings = {'false', 'true'};
    if ~strcmp(type, 'boolean')
        this.addError(path, sprintf('does not match type %s', type), value);
        return;
    end
end

if strcmp(type, 'object')
    if isfield(schema, 'required')
        for i=1:length(schema.required)
            if ~isfield(value, schema.required{i})
                this.addError(path, sprintf('is missing required field %s', schema.required{i}), value);
            end
        end
    end
    newValue = mergeDefaults(value, schema);
elseif strcmp(type, 'string')
    if isfield(schema, 'pattern')
        if ~regexp(value, schema.pattern)
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
            this.addError(badPath, sprintf('is smaller than minimum %f', schema.minimum), value);
        end
    end
    
    if isfield(schema, 'maximum')
        badPath = getBadPath(path, value > schema.maximum);
        if ~isempty(badPath)
            this.addError(badPath, sprintf('is bigger than maximum %f', schema.maximum), value);
        end
    end
end

if isfield(schema, 'enum')
    if ~ismember(value, schema.enum)
        this.addError(path, 'is not contained in enumeration', value);
    end
end

end

