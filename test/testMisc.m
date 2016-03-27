addpath('../lib');

tc = TestCase();

[json, errors] = JSON.stringify({'foo'}, struct('type', 'object'));

[json, errors] = JSON.stringify(pi, struct('type', 'integer'), 0);

[obj, errors] = JSON.parse('[1,2]a');
tc.assertEqual(errors{1}{2}, 'Unexpected trailing text [1,2]a^^^');

[obj, errors] = JSON.parse('a[1,2]');
tc.assertEqual(errors{1}{2}, 'Illegal token a^^^[1,2]');

% Check for invalid chars in string "fo\x01o"
[obj, errors] = JSON.parse(char([34  102  111 1 111 34]));
tc.assertEqual(errors{1}{2}, ['Invalid char found in range #00-#1F "fo' char(1) '^^^o"']);

%%% Comprehensive Tests

[obj, errors] = JSON.parse('file:document.json', 'file:schema.json');

m = JSON_Parser.cellToMat({1 2});
assert(isequal(m, [1 2]));

m = JSON_Parser.cellToMat({{1} {2}});
assert(isequal(m, [1;2]));

m = JSON_Parser.cellToMat({{1 2} {[] 4}});
assert(isequaln(m, [1 2;NaN 4]));

m = JSON_Parser.cellToMat({{{1 2} {3 4}} {{5 6} {7 8}}});
assert(isequal(squeeze(m(1,:,:)), [1 2;3 4]));
assert(isequal(squeeze(m(2,:,:)), [5 6; 7 8]));
assert(isequal(m, permute(cat(3, [1 3;2 4], [5 7; 6 8]), [3 2 1])));

m = JSON_Parser.cellToMat({1 NaN 3});
assert(isequaln(m, [1 NaN 3]));

% A JSON Schema is a JSON document, and that document MUST be an object
[obj, errors] = JSON.parse('1', '2');
assert(strcmp(errors{1}{2}, 'A JSON Schema MUST be an object'));

m = containers.Map();
m('a') = 1;
m('_*') = 2;
assert(m('a') == 1);
assert(m('_*') == 2);
assert(isequal(m.keys(), {'a', '_*'}));
assert(m.isKey('a'));
assert(m.isKey('_*'));



obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};
obj('foo/bar') = 42; % Not recommended! 
assert(JSON.getPath(obj, '/foo/bar') == 13)
assert(strcmp(JSON.getPath(obj, '/bar/1'), 'bar'))
assert(JSON.getPath(obj, '/foo~1bar') == 42)
assert(JSON.getPath(obj, '/foobar', 4711) == 4711)