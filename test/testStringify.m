addpath('../');
addpath('../../../../menergy/time');

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

[json, errors] = JSON_stringifyValidate(obj, 'file:schema.json', 4);

tokens = regexp(json, ':\s*(\d+(\.\d*)?)', 'tokens');
assert(strcmp(tokens{1}, '3.14'));
assert(strcmp(tokens{2}, '3.1415926536'));
assert(strcmp(tokens{3}, '3'));

obj = struct;
obj.id = '4711';
obj.myArray = s;

% Test struct arrays
d = now;
s = struct([]);
s(1).name = 'foo';
s(1).start = d;
s(1).ende = d+1;

s(2).name = 'bar';
s(2).start = d+2;
s(2).ende = d+3;

json1 = JSON_stringifyValidate(obj, 'file:schema.json', 4)

% Test cell arrays
s = {struct, struct};
s{1}.name = 'foo';
s{1}.start = d;
s{1}.ende = d+1;

s{2}.name = 'bar';
s{2}.start = d+2;
s{2}.ende = d+3;

obj.myArray = s;

[json2, errors] = JSON_stringifyValidate(obj, 'file:schema.json', 4)

assert(strcmp(json1, json2))