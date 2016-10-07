jsonOrFilepath = 'document.json';
[obj, errors] = JSON.parse(jsonOrFilepath, 'schema.json');

obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};

json = JSON.stringify(obj);
[json, errors] = JSON.stringify(obj, 'schema.json');