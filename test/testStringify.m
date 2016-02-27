function testStringify(description)

%clear classes;
%addpath('../lib');

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory')
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', 'stringify.xml')
document = builder.parse(file);

tests = document.getChildNodes().item(0).getElementsByTagName('test');


fprintf(1, '| MATLAB | Schema | JSON | Errors |\n');
fprintf(1, '|--------|--------|------|--------|\n');

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    getElem = @(tagName) strrep(strtrim(test.getElementsByTagName(tagName).item(0).getTextContent()), repmat(' ', 1, 12), '');

    desc = getElem('description');
    if isempty(desc) || (nargin >= 1 && ~strcmp(desc, description))
        continue;
    end

    code = getElem('matlab');
    schema = getElem('schema');
    json = getElem('json');
    errorText = getElem('errors');

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    [jsonOut, errors] = JSON_Stringifier.stringify(eval(code), schema, 0);

    fprintf(1, '| %s |\n', desc);
    fprintf(1, '| %s | %s | %s | %s |\n', strrep(code, sprintf('\n'), '<br/>'), strrep(schema, sprintf('\n'), '<br/>'), strrep(json, sprintf('\n'), '<br/>'), strrep(errorText, sprintf('\n'), '<br/>'));

    if isempty(errors)
        errors = {};
    end

    if ~strcmp(json, jsonOut)
        keyboard
        fprintf(1, 'Expected: %s\n', json);
        fprintf(1, 'Actual: %s\n', jsonOut);
    end

    if ~isequal(expectedErrors, errors)
        celldisp(expectedErrors);
        celldisp(errors);
    end

end

fprintf(1, '\n\n');
