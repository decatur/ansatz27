[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', 'schema.json');
if ~isempty(errors)
    % Report errors and stop processing
end