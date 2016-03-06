function testValidation(description)

dir = fileparts(mfilename ("fullpath"));
fid = fopen(fullfile(dir, '..', 'build', 'validation.md'), 'w');

function append(format, varargin)
    fprintf(fid, [format '\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', fullfile(dir, 'testValidation.xml'));
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');

append('| MATLAB |  JSON  | Schema | Errors |');
append('|--------|--------|--------|--------|');

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '%s\n', desc);

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    json = getElementText(test, 'json');
    errorText = getElementText(test, 'errors');

    append('| %s |', desc);
    append('| %s | %s | %s | %s |', nl(code), nl(json), nl(schema), nl(errorText));

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    [jsonOut, errors] = JSON_Stringifier.stringify(a, schema, 0);

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
