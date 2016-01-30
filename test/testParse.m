addpath('../');

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


