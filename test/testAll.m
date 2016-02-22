clear classes;
addpath('../lib');

testData = JSON_Handler.readFileToString('testData.txt', 'latin1');
tests = strsplit(testData, '#### Description');

fprintf(1, '| MATLAB | Schema | JSON | Errors |\n');
fprintf(1, '|--------|--------|------|--------|\n');

for k=1:length(tests)
    test = strtrim(tests{k});
    if isempty(test)
        continue;
    end
    parts = strsplit(test, '#');
    desc = strtrim(parts{1});
    code = strtrim(parts{2});
    if isempty(code)
        continue;
    end
    schema = strtrim(parts{3});
    json = strtrim(parts{4});
    errorText = strtrim(parts{5});

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    [jsonOut, errors] = JSON_Stringifier.stringify(eval(code), schema, 0);

    fprintf(1, '| %s |\n', desc);
    fprintf(1, '| %s | %s | %s | %s |', strrep(code, sprintf('\n'), '<br/>'), strrep(schema, sprintf('\n'), '<br/>'), strrep(json, sprintf('\n'), '<br/>'), strrep(errorText, sprintf('\n'), '<br/>'));

    if isempty(errors)
        errors = {};
    end

    assert(strcmp(json, jsonOut));
    assert(isequal(expectedErrors, errors));

end

fprintf(1, '\n\n');
