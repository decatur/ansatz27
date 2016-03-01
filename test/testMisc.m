addpath('../lib');

[json, errors] = JSON_Stringifier.stringify({'foo'}, struct('type', 'object'));

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'integer'), 0);

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

%%% Comprehensive Tests

[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json');

assert(isempty(obj.foo))
assert(obj.date == 736355)
assert(obj.datetime == 736355.5)

expectedErrors = { ...
    {'/minNumber/', 'is smaller than minimum 3', '1'}, ...
    {'/matrix/2/2/', 'is smaller than minimum 0', '-5'}, ...
    {'/myArray/2/myNumber/', 'is smaller than minimum 0', '-3.1415'}, ...
};