obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};
obj('foo/bar') = 42;    % Not recommended!
obj('') = 14;           % Not recommended! 
assert(JSON.getPath(obj, '/foo/bar') == 13)
assert(strcmp(JSON.getPath(obj, '/bar/1'), 'bar'))
assert(JSON.getPath(obj, '/foo~1bar') == 42)
assert(JSON.getPath(obj, '/') == 14)
assert(JSON.getPath(obj, '/foobar', 4711) == 4711)

obj = containers.Map();
obj('foo') = containers.Map();
c = obj('foo');
c('bar') = {1 2 3};
JSON.setPath(obj, '/foo/bar/1', 42);
assert(JSON.getPath(obj, '/foo/bar/1') == 42);

obj = JSON.setPath({1 2 3 4}, '/1', 42);
assert(isequal(obj, {1 42 3 4}));

obj = JSON.setPath({1 2 3 4}, '/5', 42);
assert(isequal(obj, {1 2 3 4 [] 42}));