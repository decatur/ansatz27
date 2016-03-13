function testValidation(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testValidation.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

fid = fopen(fullfile(dir, '..', 'build', 'validation.md'), 'w');

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '%s\n', desc);

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    jsonExpected = getElementText(test, 'json');
    errorText = getElementText(test, 'errors');

    if strcmp(char(test.getAttribute('readme')), 'true')
        fprintf(fid, '### %s\n', desc);
        if ~isempty(code)
            fprintf(fid, 'MATLAB\n```MATLAB\n%s\n```\n', code);
        end
        if ~isempty(jsonExpected)
            fprintf(fid, 'JSON\n```JSON\n%s\n```\n\n', jsonExpected);
        end
        fprintf(fid, 'Schema\n```JSON\n%s\n```\n', schema);
        fprintf(fid, 'Errors\n```MATLAB\n%s\n```\n', errorText);
    end

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);
    for k=1:length(expectedErrors)
        expectedErrors{k} = [expectedErrors{k} 'JSON:SCHEMA_VALIDATION'];
    end

    
    if ~isempty(code)
        if isempty(regexp(code, '^a\s*='))
            a = eval(code);
        else
            eval(code);
        end 

        [jsonActual, actualErrors] = JSON.stringify(a, schema, 0);
        tc.assertEqual(actualErrors, expectedErrors);
    end

    if ~isempty(jsonExpected)
        [actualMatlab, actualErrors] = JSON.parse(jsonExpected, schema);
        tc.assertEqual(actualErrors, expectedErrors);
    end

end

fclose(fid);

end
