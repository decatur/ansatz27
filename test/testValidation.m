function testValidation(description)

fid = fopen ('../build/validation.md', 'w');

function append(format, varargin)
    fprintf(fid, [format '\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', 'testValidation.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');

append('| MATLAB |  JSON  | Schema | Errors |');
append('|--------|--------|--------|--------|');

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    getElem = @(tagName) regexprep(strtrim(test.getElementsByTagName(tagName).item(0).getTextContent()), '\n\s{10}', '\n');

    desc = getElem('description');
    if isempty(desc) || (nargin >= 1 && ~strcmp(desc, description))
        continue;
    end

    code = getElem('matlab');
    schema = getElem('schema');
    json = getElem('json');
    errorText = getElem('errors');

    append('| %s |', desc);
    append('| %s | %s | %s | %s |', nl(code), nl(json), nl(schema), nl(errorText));

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    [jsonOut, errors] = JSON_Stringifier.stringify(eval(code), schema, 0);

    if ~isequal(expectedErrors, errors)
        fprintf(1, 'stringify\n');
        expectedErrors
        errors
    end

    [objOut, errors] = JSON_Parser.parse(json, schema);

    if ~isequal(expectedErrors, errors)
        fprintf(1, 'parse\n');
        expectedErrors
        errors
    end

end

fclose(fid);

end
