function testStringify(description)

fid = fopen ('../build/stringify.md', 'w');

function append(format, varargin)
    fprintf(fid, [format '\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();
file = javaObject('java.io.File', 'testStringify.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');


append('| MATLAB | Schema | JSON |');
append('|--------|--------|------|');

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

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    [jsonOut, errors] = JSON_Stringifier.stringify(a, schema, 0);

    append('| %s |', desc);
    append('| %s | %s | %s |', nl(code), nl(schema), nl(json));

    assert(isempty(errors));

    if ~strcmp(json, jsonOut)
        keyboard
        fprintf(1, 'Expected: %s\n', json);
        fprintf(1, 'Actual: %s\n', jsonOut);
    end

end


fclose(fid);

end

