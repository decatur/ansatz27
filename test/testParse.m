addpath('../lib');

[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json');

assert(isempty(obj.foo))
assert(obj.date == 736355)
assert(obj.datetime == 736355.5)

expectedErrors = { ...
    'At /minNumber/ value is smaller than minimum 3.000000', ...
    'At /matrix/2/2 value is smaller than minimum 0.000000', ...
    'At /myArray/2/myNumber/ value is smaller than minimum 0.000000', ...
    'At /invalidSchema/ no type specified'
};

assert(isequal(errors, expectedErrors));

[json, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json', 4);

[obj, errors] = JSON_Parser.parse('["foo"]')
assert(isequal(obj, cellstr('foo')))

[obj, errors] = JSON_Parser.parse('["foo"]', struct('type', 'object'));
assert(isequal(obj, cellstr('foo')));
assert(numel(errors) == 2);

[obj, errors] = JSON_Parser.parse('["foo"]', struct('type', 'array'));
assert(isequal(obj, cellstr('foo')));
assert(isempty(errors));

[json, errors] = JSON_Stringifier.stringify('foo', struct('type', 'number'));
assert(strcmp(json, '"foo"'));
assert(isequal(errors, cellstr('At / value foo does not match type number')));

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'number'));
assert(isempty(errors));
assert(strcmp(num2str(pi, 11), json));

[json, errors] = JSON_Stringifier.stringify(struct('foo', 'bar'), [], 0);
assert(isempty(errors));
assert(strcmp(json, '{"foo": "bar"}'));

[json, errors] = JSON_Stringifier.stringify(cellstr('foo'), struct('type', 'object'));

[json, errors] = JSON_Stringifier.stringify(struct(), struct('type', 'object', 'properties', []))

schema = JSON_Parser.parse('file:schema.json')
[json, errors] = JSON_Stringifier.stringify(cellstr('foo'), schema)

[json, errors] = JSON_Stringifier.stringify(struct());
assert(isempty(errors));
assert(strcmp(json, sprintf('{\r\n\r\n}')));

[json, errors] = JSON_Stringifier.stringify(struct(), [], 0);
assert(isempty(errors));
assert(strcmp(json, sprintf('{}')));