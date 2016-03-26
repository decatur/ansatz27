function testValidation(description)

dir = fileparts(mfilename ('fullpath'));

document = xmlread(fullfile(dir, 'testValidation.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '%s', desc);

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    jsonExpected = getElementText(test, 'json');
    errorText = getElementText(test, 'errors');

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    if ~isempty(code)
        fprintf(1, '\t\tstringify ... ');
        if isempty(regexp(code, '^a\s*=', 'once'))
            a = eval(code);
        else
            eval(code);
        end 

        [jsonActual, actualErrors] = JSON.stringify(a, schema, 0);
        for l=1:length(actualErrors)
            actualErrors{l} = actualErrors{l}(1:end-1);
        end
    
        tc.assertEqual(actualErrors, expectedErrors);
    end

    if ~isempty(jsonExpected)
        fprintf(1, '\t\tparse ... ');
        [actualMatlab, actualErrors] = JSON.parse(jsonExpected, schema);
        for l=1:length(actualErrors)
            actualErrors{l} = actualErrors{l}(1:end-1);
        end
        tc.assertEqual(actualErrors, expectedErrors);
    end

    fprintf(1, '\n');

end

end
