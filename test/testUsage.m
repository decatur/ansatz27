% Parse a literal JSON string
[obj, errors] = JSON.parse('{"id": "MyId", "value": 3.14}');

% Parse JSON from URI
[obj, errors] = JSON.parse('document.json', 'schema.json');

obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};

json = JSON.stringify(obj);
[json, errors] = JSON.stringify(obj, 'schema.json');

% For performance, explicitely parse a schema to use it for multiple parses or stringifies
schema = JSON.loadSchema('schema.json');
[obj, errors] = JSON.parse('document.json', schema);
[json, errors] = JSON.stringify(obj, schema);