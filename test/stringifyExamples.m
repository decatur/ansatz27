addpath('../lib');
clear classes;

[json, errors] = JSON_Stringifier.stringify({'foo'}, struct('type', 'object'));

[json, errors] = JSON_Stringifier.stringify(pi, struct('type', 'integer'), 0);









