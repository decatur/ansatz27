addpath('../lib');

[json, errors] = JSON.stringify({'foo'}, struct('type', 'object'));

[json, errors] = JSON.stringify(pi, struct('type', 'integer'), 0);

try
    [obj, errors] = JSON.parse('[1,2]a');
    assert(false);
catch e
    assert(strcmp(e.message, 'Unexpected char [1,2]a^^^'));
end

try
    [obj, errors] = JSON.parse('a[1,2]');
    assert(false);
catch e
    assert(strcmp(e.message, 'Illegal token a^^^[1,2]'));
end

% Check for invalid chars in string "fo\x01o"
try
    JSON.parse(char([34  102  111 1 111 34]));
    assert(false);
catch e
    assert(strcmp(e.message, ['Invalid char found in range #00-#1F "fo' char(1) '^^^o"']));
end

%%% Comprehensive Tests

[obj, errors] = JSON.parse('file:document.json', 'file:schema.json');

m = cellToMat({1 2});
assert(isequal(m, [1 2]));

m = cellToMat({{1} {2}});
assert(isequal(m, [1;2]));

m = cellToMat({{1 2} {[] 4}});
assert(isequaln(m, [1 2;NaN 4]));

m = cellToMat({{{1 2} {3 4}} {{5 6} {7 8}}});
assert(isequal(squeeze(m(1,:,:)), [1 2;3 4]));
assert(isequal(squeeze(m(2,:,:)), [5 6; 7 8]));
assert(isequal(m, permute(cat(3, [1 3;2 4], [5 7; 6 8]), [3 2 1])));

m = cellToMat({1 NaN 3});
assert(isequaln(m, [1 NaN 3]));
