[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', 'roundtrip/Comprehensive_Example/schema.json');
if ~isempty(errors)
    % Report errors and stop processing
end