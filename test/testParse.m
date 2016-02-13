addpath('../lib');

[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json');

assert(isempty(obj.foo))
assert(obj.date == 736355)
assert(obj.datetime == 736355.5)

expectedErrors = { ...
    'At /minNumber/ value is smaller than minimum 3.000000', ...
    'At /matrix/2/2 value is smaller than minimum 0.000000', ...
    'At /myArray/2/myNumber/ value is smaller than minimum 0.000000', ...
    'At /invalidSchema/ no type specified', ...
    'At / missing required field ID'};

assert(isequal(errors, expectedErrors));

%[json, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json');

[obj, errors] = JSON_Parser.parse('["foo"]');
assert(isempty(errors));
assert(isequal(obj, cellstr('foo')));

[obj, errors] = JSON_Parser.parse('["foo"]', struct('type', 'object'));
assert(isequal(obj, cellstr('foo')));
assert(numel(errors) == 1);
assert(strcmp(errors{1}, 'At / value does not match type object'));

[obj, errors] = JSON_Parser.parse('["foo"]', struct('type', 'array'));
assert(isempty(errors));
assert(isequal(obj, cellstr('foo')));

[obj, errors] = JSON_Parser.parse('1', struct('type', 'number'));
assert(isempty(errors));
assert(obj == 1);

[obj, errors] = JSON_Parser.parse('true', struct('type', 'boolean'));
assert(isempty(errors));
assert(islogical(obj) && obj == true);

[obj, errors] = JSON_Parser.parse('{"foo":1}');
assert(isempty(errors));
assert(isequal(obj, struct('foo', 1)));

[obj, errors] = JSON_Parser.parse('{"foo":1}', struct('type', 'object'));
assert(isempty(errors));
assert(isequal(obj, struct('foo', 1)));

schema = JSON_Parser.parse('file:schema.json');

