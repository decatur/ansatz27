addpath('../lib');
clear classes;

[json, errors] = JSON_Stringifier.stringify(struct('foo', 'bar'), [], 0);
assert(strcmp(json, '{"foo":"bar"}'));

[json, errors] = JSON_Stringifier.stringify(cellstr('foo'), struct('type', 'object'));

[json, errors] = JSON_Stringifier.stringify(struct(), struct('type', 'object', 'properties', []));
assert(isempty(errors));

[json, errors] = JSON_Stringifier.stringify(cellstr(['foo'; 'bar']), [], 0);
assert(strcmp(json, '["foo","bar"]'));

[json, errors] = JSON_Stringifier.stringify(struct());
assert(strcmp(json, sprintf('{\r\n\r\n}')));

[json, errors] = JSON_Stringifier.stringify(struct(), [], 0);
assert(strcmp(json, '{}'));

[json, errors] = JSON_Stringifier.stringify(struct('foo', {1 2}), [], 0);
assert(strcmp(json, '[{"foo":1},{"foo":2}]'));

[json, errors] = JSON_Stringifier.stringify([1 2], [], 0);
assert(strcmp(json, '[1,2]'));

[json, errors] = JSON_Stringifier.stringify([1 2]', [], 0);
assert(strcmp(json, '[1,2]'));

[json, errors] = JSON_Stringifier.stringify(1);
assert(strcmp(json, '1'));

[json, errors] = JSON_Stringifier.stringify(Inf);
assert(strcmp(json, 'null'));

[json, errors] = JSON_Stringifier.stringify([Inf 1], [], 0);
assert(strcmp(json, '[null,1]'));

[json, errors] = JSON_Stringifier.stringify(true, [], 0);
assert(strcmp(json, 'true'));

[json, errors] = JSON_Stringifier.stringify([true false], [], 0);
assert(strcmp(json, '[true,false]'));

[json, errors] = JSON_Stringifier.stringify('foo', [], 0);
assert(strcmp(json, '"foo"'));

matrix3D = NaN(2,2,2);
matrix3D(1,:,:) = [1 2; 3 4];
matrix3D(2,:,:) = 4 + matrix3D(1,:,:);
[json, errors] = JSON_Stringifier.stringify(matrix3D, [], 0);
%assert(strcmp(json, '[[[1,2],[3,4]],[[5,6],[7,8]]]'));

%%% Test schema hinting

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'integer'), 0);

clear classes
schema = struct();
schema.type = 'array';
schema.items.type = {'number' 'null'};
[json, errors] = JSON_Stringifier.stringify(1, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[1]'));

[json, errors] = JSON_Stringifier.stringify(NaN, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[null]'));

[json, errors] = JSON_Stringifier.stringify([], schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[]'));

[json, errors] = JSON_Stringifier.stringify([1 NaN Inf -Inf 2], schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[1,null,null,null,2]'));

schema.items.fixedPrecision = 2;
[json, errors] = JSON_Stringifier.stringify(1, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[1.00]'));

clear classes
schema = struct();
schema.type = 'object';
schema.properties = struct('foo', struct('type', 'array'));
[json, errors] = JSON_Stringifier.stringify(struct('foo', 1), schema, 0);
assert(isempty(errors));
assert(strcmp(json, '{"foo":[1]}'));

clear classes
schema = struct();
schema.type = 'array';
schema.items.type = 'array';
schema.items.items.type = {'number' 'null'};
[json, errors] = JSON_Stringifier.stringify(1, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[[1]]'));

schema.items.items.fixedPrecision = 2;
[json, errors] = JSON_Stringifier.stringify(1, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[[1.00]]'));

[json, errors] = JSON_Stringifier.stringify([1 NaN; Inf 2], schema, 0);
assert(strcmp(json, '[[1.00,null],[null,2.00]]'));

clear classes
schema = struct();
schema.type = {'array' 'null'};
schema.items.type = 'object';

[json, errors] = JSON_Stringifier.stringify([], schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[]'));

[json, errors] = JSON_Stringifier.stringify(struct('foo', {1 2}), schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[{"foo":1},{"foo":2}]'));

[json, errors] = JSON_Stringifier.stringify({struct('foo', 1)}, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[{"foo":1}]'));

[json, errors] = JSON_Stringifier.stringify({struct('foo', 1) struct('foo', 2)}, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '[{"foo":1},{"foo":2}]'));


%%% Test schema validation

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'number'));
assert(isempty(errors));
assert(strcmp(num2str(pi, 11), json));

clear classes
schema = struct();
schema.type = 'array';
schema.items.type = 'string';
[json, errors] = JSON_Stringifier.stringify({'foo' 'bar'}, schema, 0);
assert(isempty(errors));
assert(strcmp(json, '["foo","bar"]'));

clear classes
schema = struct();
schema.type = 'object';
schema.required = {'bar'};
[json, errors] = JSON_Stringifier.stringify(struct('foo', 1), schema, 0);
assert(strcmp(json, '{"foo":1}'));
assert(isequal(errors{1}, {'/' 'is missing required field bar' '{object}'}));



[json, errors] = JSON_Stringifier.stringify([1 2], struct('type', 'object'));
assert(isequal(errors{1}(1:2), {'/' 'does not match type'}));

[json, errors] = JSON_Stringifier.stringify('foo', struct('type', 'number'));
assert(isequal(errors{1}(1:2), {'/' 'does not match type'}));

[json, errors] = JSON_Stringifier.stringify([1 2], struct('type', 'number'));
assert(isequal(errors{1}(1:2), {'/' 'does not match type'}));

[json, errors] = JSON_Stringifier.stringify(1, struct('type', 'number'));
assert(isempty(errors));

[json, errors] = JSON_Stringifier.stringify([1 2], struct('type', 'number'));
assert(isequal(errors{1}(1:2), {'/' 'does not match type'}));

[json, errors] = JSON_Stringifier.stringify(true, struct('type', 'number'));
assert(isequal(errors{1}(1:2), {'/' 'does not match type'}));

[json, errors] = JSON_Stringifier.stringify('Hello', struct('type', 'string', 'pattern', '^\w+$'));
assert(isempty(errors));

[json, errors] = JSON_Stringifier.stringify('Hello World', struct('type', 'string', 'pattern', '^\w+$'));
assert(isequal(errors{1}(1:2), {'/' 'does not match pattern ^\w+$'}));

%%% Comprehensive test

obj = struct;
obj.fixNumber = pi;
obj.number = pi;
obj.nan = NaN;
obj.vector = [1 NaN 2 Inf 3 -Inf 4];
obj.vector1 = obj.vector';
obj.matrix = [1 2; 3 4];

[json, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json', 0);
expectedJSON = JSON_Stringifier.readFileToString('doc1.json', 'latin1');
assert(isempty(errors));
assert(strcmp(json, expectedJSON));

% Test struct arrays
obj = struct;
obj.id = '4711';

d = now;
s = struct([]);
s(1).name = 'foo';
s(1).start = d;
s(1).ende = d+1;

s(2).name = 'bar';
s(2).start = d+2;
s(2).ende = d+3;

obj.myArray = s;

json1 = JSON_Stringifier.stringify(obj, 'file:schema.json');

% Test cell arrays
s = {struct, struct};
s{1}.name = 'foo';
s{1}.start = d;
s{1}.ende = d+1;

s{2}.name = 'bar';
s{2}.start = d+2;
s{2}.ende = d+3;

obj.myArray = s;

[json2, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json');

assert(strcmp(json1, json2));


