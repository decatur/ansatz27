function testStringify(description)

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();
file = javaObject('java.io.File', 'testStringify.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');


fprintf(1, '| MATLAB | Schema | JSON |\n');
fprintf(1, '|--------|--------|------|\n');

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

    [jsonOut, errors] = JSON_Stringifier.stringify(eval(code), schema, 0);

    fprintf(1, '| %s |\n', desc);
    fprintf(1, '| %s | %s | %s |\n', nl(code), nl(schema), nl(json));

    assert(isempty(errors));

    if ~strcmp(json, jsonOut)
        keyboard
        fprintf(1, 'Expected: %s\n', json);
        fprintf(1, 'Actual: %s\n', jsonOut);
    end

end

fprintf(1, '\n\n');
