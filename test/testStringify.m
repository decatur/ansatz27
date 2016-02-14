addpath('../lib');

obj = struct;
obj.fixNumber = pi;
obj.number = pi;
obj.integer = pi;
obj.nan = NaN;
obj.vector = [1 NaN 2 Inf 3 -Inf 4];
obj.vector1 = obj.vector';
obj.matrix = [1 2; 3 4];
obj.matrix3D = NaN(2,2,2);
obj.matrix3D(1,:,:) = [1 2; 3 4];
obj.matrix3D(2,:,:) = 4+obj.matrix3D(1,:,:);
obj.minNumber = 1;

[json, errors] = JSON_Stringifier.stringify(obj, 'file:schema.json');
expectedJSON = JSON_Stringifier.readFileToString('doc1.json', 'latin1');
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

[json, errors] = JSON_Stringifier.stringify('foo', struct('type', 'number'));
assert(strcmp(json, '"foo"'));
assert(isequal(errors{1}, {'/' 'does not match type number' 'foo'}));

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'number'));
assert(isempty(errors));
assert(strcmp(num2str(pi, 11), json));

[json, errors] = JSON_Stringifier.stringify(struct('foo', 'bar'), [], 0);
assert(isempty(errors));
assert(strcmp(json, '{"foo": "bar"}'));

[json, errors] = JSON_Stringifier.stringify(cellstr('foo'), struct('type', 'object'));

[json, errors] = JSON_Stringifier.stringify(struct(), struct('type', 'object', 'properties', []));
assert(isempty(errors));

[json, errors] = JSON_Stringifier.stringify(cellstr(['foo'; 'bar']), [], 0);
assert(isempty(errors));
assert(strcmp(json, '["foo","bar"]'));

[json, errors] = JSON_Stringifier.stringify(struct());
assert(isempty(errors));
assert(strcmp(json, sprintf('{\r\n\r\n}')));

[json, errors] = JSON_Stringifier.stringify(struct(), [], 0);
assert(isempty(errors));
assert(strcmp(json, '{}'));

[json, errors] = JSON_Stringifier.stringify(struct('foo', {1 2}), [], 0);
assert(isempty(errors));
assert(strcmp(json, '[{"foo": 1},{"foo": 2}]'));

[json, errors] = JSON_Stringifier.stringify([1 2], [], 0);
assert(isempty(errors));
assert(strcmp(json, '[1, 2]'));

[json, errors] = JSON_Stringifier.stringify(1, [], 0);
assert(isempty(errors));
assert(strcmp(json, '1'));

[json, errors] = JSON_Stringifier.stringify(true, [], 0);
assert(isempty(errors));
assert(strcmp(json, 'true'));

[json, errors] = JSON_Stringifier.stringify('foo', [], 0);
assert(isempty(errors));
assert(strcmp(json, '"foo"'));

[json, errors] = JSON_Stringifier.stringify(struct(), 'file:schema1.json', 0);
assert(strcmp(json, '{"foo": ""}'));

[json, errors] = JSON_Stringifier.stringify([1 2], struct('type', 'object'));