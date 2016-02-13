% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function newValue = validate(this, value, actType, schema, path)

newValue = value;

if ~isfield(schema, 'type')
    this.addError(sprintf('At %s no type specified', path));
    return
end

type = schema.type;

if strcmp(actType, 'string')
    if ~strcmp(type, 'string')
        this.addError(sprintf('At %s value %s does not match type %s', path, value, type));
        return;
    end
elseif strcmp(actType, 'object') || strcmp(actType, 'array')
    if ~ismember(actType, type)
        this.addError(sprintf('At %s value does not match type', path));
        return;
    end
elseif strcmp(actType, 'number')
    if ~strcmp(type, 'number') && ~strcmp(type, 'integer')
        this.addError(sprintf('At %s value %f does not match type %s', path, value, type));
        return;
    end
elseif strcmp(actType, 'boolean')
    booleanStrings = {'false', 'true'};
    if ~strcmp(type, 'boolean')
        this.addError(sprintf('At %s boolean true does not match type %s', path, booleanStrings{value+1}, type));
        return;
    end
end

if strcmp(type, 'object')
    if isfield(schema, 'required')
        for i=1:length(schema.required)
            if ~isfield(value, schema.required{i})
                this.addError(sprintf('At %s missing required field %s', path, schema.required{i}));
            end
        end
    end
    newValue = mergeDefaults(value, schema);
elseif strcmp(type, 'string')
    if isfield(schema, 'pattern')
        if ~regexp(value, schema.pattern)
            this.addError(sprintf('At %s value %s does not match %s', path, value, schema.pattern));
        end
    end
    
    format = getPath(schema, 'format');
    
    if strcmp(format, 'date')
        if ~regexp(value, '^\d{4}-\d{2}-\d{2}$')
            this.addError(sprintf('At %s value is not a date: %s', path, value));
        end
    end
    
elseif isnumeric(value)
    
    if strcmp(type, 'integer')
        badPath = getBadPath(path, rem(value, 1));
        if ~isempty(badPath)
            this.addError(sprintf('At %s value is not an integer', badPath));
        end
    end
    
    if isfield(schema, 'minimum')
        badPath = getBadPath(path, value < schema.minimum);
        if ~isempty(badPath)
            this.addError(sprintf('At %s value is smaller than minimum %f', badPath, schema.minimum));
        end
    end
    
    if isfield(schema, 'maximum')
        badPath = getBadPath(path, value > schema.maximum);
        if ~isempty(badPath)
            this.addError(sprintf('At %s value %f is bigger than maximum %f', badPath, schema.maximum));
        end
    end
end

if isfield(schema, 'enum')
    if ~ismember(value, schema.enum)
        this.addError(sprintf('At %s value is not contained in enumeration', path));
    end
end

end

