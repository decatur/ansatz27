addpath('../lib');
debug_on_error(false);
clear all;

[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json');

assert(isempty(obj.foo))
assert(obj.date == 736355)
assert(obj.datetime == 736355.5)

expectedErrors = { ...
    {'/minNumber/', 'is smaller than minimum 3.000000', '1'}, ...
    {'/matrix/2/2', 'is smaller than minimum 0.000000', '4  -5   6'}, ...
    {'/myArray/2/myNumber/', 'is smaller than minimum 0.000000', '-3.1415'}, ...
    {'/invalidSchema/', 'has no type specified', '3'}, ...
};

assert(isequal(errors, expectedErrors));

%[json, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json');

[obj, errors] = JSON_Parser.parse('["foo"]');
assert(isempty(errors));
assert(isequal(obj, cellstr('foo')));

[obj, errors] = JSON_Parser.parse('["foo"]', struct('type', 'object'));
assert(isequal(obj, cellstr('foo')));
assert(numel(errors) == 1);
assert(isequal(errors{1}, {'/' 'does not match type object' '[array]'}));

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


%%% Test enum validation

schema = struct('type', 'string');
schema.enum = {'foo', 'bar'};
[obj, errors] = JSON_Parser.parse('"foo"', schema);
assert(isempty(errors));

[obj, errors] = JSON_Parser.parse('"foo1"', schema);
assert(numel(errors) == 1);
assert(isequal(errors{1}, {'/' 'is not contained in enumeration' 'foo1'}));

schema = struct('type', 'integer');
schema.enum = {1, 2};
[obj, errors] = JSON_Parser.parse('1', schema);
assert(numel(errors) == 0);

[obj, errors] = JSON_Parser.parse('3', schema);
assert(numel(errors) == 1);
assert(isequal(errors{1}, {'/' 'is not contained in enumeration' '3'}));

[obj, errors] = JSON_Parser.parse('[1,2]');
assert(isequal(obj, {1 2}));

schema = struct('type', 'array');
schema.items.type = {'number', 'object'};
[obj, errors] = JSON_Parser.parse('[1,{},2]', schema);
assert(numel(errors) == 0);
assert(isequal(obj, {1, struct(), 2}));

%%% Test numerical vector

schema = struct('type', 'array');
schema.items.type = 'number';
[obj, errors] = JSON_Parser.parse('[1,2]', schema);
assert(isempty(errors));
assert(isequal(obj, [1, 2]));

schema = struct('type', 'array');
schema.items.type = 'number';
[obj, errors] = JSON_Parser.parse('[1,null,2]', schema);
assert(isempty(errors));
assert(isequaln(obj, [1, NaN, 2]));

schema = struct('type', 'array');
schema.items.type = {'number', 'null'};
[obj, errors] = JSON_Parser.parse('[1,null,2]', schema);
assert(numel(errors) == 0);
assert(isequaln(obj, [1, NaN, 2]));

try
    [obj, errors] = JSON_Parser.parse('[1,2]a');
    assert(false);
catch e
    assert(strcmp(e.message, 'Unexpected char [1,2]a^^^'));
end

try
    [obj, errors] = JSON_Parser.parse('a[1,2]');
    assert(false);
catch e
    assert(strcmp(e.message, 'Illegal token a^^^[1,2]'));
end

% Check for invalid chars in string "fo\x01o"
try
    JSON_Parser.parse(char([34  102  111 1 111 34]));
    assert(false);
catch e
    assert(strcmp(e.message, ['Invalid char found in range #00-#1F "fo' char(1) '^^^o"']));
end

% Test matrices

[obj, errors] = JSON_Parser.parse('[ [1, 2, 3], [4, -5, 6] ]');

schema = struct('type', 'array');
schema.items.type = 'array';
schema.items.items.type = 'number';
[obj, errors] = JSON_Parser.parse('[ [1, 2, 3], [4, -5, 6] ]', schema);
assert(isequal(obj, [ [1 2 3]; [4 -5 6] ]));

schema = struct('type', 'array');
schema.items.type = 'array';
schema.items.items.type = {'number', 'null'};
[obj, errors] = JSON_Parser.parse('[ [1, 2, 3], [4, null, 6] ]', schema);
assert(isequaln(obj, [ [1 2 3]; [4 NaN 6] ]));

