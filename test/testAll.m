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
    errorLines = strtrim(parts{5});

    errorLines = strsplit(errorLines, '\n');
    expectedErrors = {};

    for l=1:length(errorLines)
        if isempty(errorLines{l})
            continue;
        end
        expectedErrors{end+1} = strsplit(errorLines{l}, '\s*\$\s*', 'delimitertype', 'regularexpression');
    end

    [jsonOut, errors] = JSON_Stringifier.stringify(eval(code), schema, 0);

    fprintf(1, '| %s |\n', desc);

    lines = cell();
    lines{1} = strsplit(code, '\n');
    lines{2} = strsplit(schema, '\n');
    lines{3} = strsplit(json, '\n');
    lines{4} = errorLines;

    %if isempty(errors)
     %   
    %else
    %    for l=1:length(errors)
    %        lines{4}{l} = strjoin(errors{l});
    %    end
    %end


    lineCount = max([numel(lines{1}) numel(lines{2}) numel(lines{3}) numel(lines{4})]);


    for l=1:lineCount
        for m=1:4
            if l<=length(lines{m})
                fprintf(1, '| %s ', lines{m}{l});
            else
                fprintf(1, '|   ');
            end
        end
    end
    
    fprintf(1, '|\n');
    fprintf(1, '|--------|--------|------|--------|\n');

    if isempty(errors)
        errors = {};
    end

    assert(strcmp(json, jsonOut));
    assert(isequal(expectedErrors, errors));

end