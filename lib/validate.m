% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function [newValue, errors] = validate(value, actType, schema, path, errors)

newValue = value;

if ~isfield(schema, 'type')
    errors = [errors, {sprintf('At %s no type specified', path)}];
    return
end

type = schema.type;

if strcmp(actType, 'string')
    if ~strcmp(type, 'string')
        errors = [errors, {sprintf('At %s, value %s does not match type %s', path, value, type)}];
    end
elseif strcmp(actType, 'object')
    if ~strcmp(type, 'object')
        errors = [errors, {sprintf('At %s, object value does not match type %s', path, type)}];
    end
elseif strcmp(actType, 'number')
    if ~strcmp(type, 'number') && ~strcmp(type, 'integer')
        errors = [errors, {sprintf('At %s, value %f does not match type %s', path, value, type)}];
    end
elseif strcmp(actType, 'boolean')
    booleanStrings = {'false', 'true'};
    if ~strcmp(type, 'boolean')
        errors = [errors, {sprintf('At %s, boolean true does not match type %s', path, booleanStrings{value+1}, type)}];
    end
end

if strcmp(type, 'object')
    if isfield(schema, 'required')
        for i=1:length(schema.required)
            if ~isfield(value, schema.required{i})
                errors = [errors, {sprintf('At %s missing required field %s', path, schema.required{i})}];
            end
        end
    end
    newValue = mergeDefaults(value, schema);
elseif strcmp(type, 'string')
    if isfield(schema, 'pattern')
        if ~regexp(value, schema.pattern)
            errors = [errors, {sprintf('At %s value %s does not match %s', path, value, schema.pattern)}];
        end
    end
    
    format = getPath(schema, 'format');
    
    if strcmp(format, 'date')
        if ~regexp(value, '^\d{4}-\d{2}-\d{2}$')
            errors = [errors, {sprintf('At %s value is not a date: %s', path, value)}];
        end
    end
    
elseif isnumeric(value)
    
    if strcmp(type, 'integer')
        badPath = getBadPath(path, rem(value, 1));
        if ~isempty(badPath)
            errors = [errors, {sprintf('At %s value is not an integer', badPath)}];
        end
    end
    
    if isfield(schema, 'minimum')
        badPath = getBadPath(path, value < schema.minimum);
        if ~isempty(badPath)
            errors = [errors, {sprintf('At %s value is smaller than minimum %f', badPath, schema.minimum)}];
        end
    end
    
    if isfield(schema, 'maximum')
        badPath = getBadPath(path, value > schema.minimum);
        if ~isempty(badPath)
            errors = [errors, {sprintf('At %s value %f is bigger than maximum %f', badPath, schema.maximum)}];
        end
    end
end

end

