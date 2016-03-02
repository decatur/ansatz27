function testRoundtrip(description)

fid = fopen ('../build/roundtrip.md', 'w');

function append(format, varargin)
    fprintf(fid, [format '\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', 'testRoundtrip.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');

append('| MATLAB | Schema | JSON |');
append('|--------|--------|------|');

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    getElem = @(tagName) regexprep(strtrim(test.getElementsByTagName(tagName).item(0).getTextContent()), '\n\s{10}', '\n');

    desc = getElem('description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '\n%s', desc);

    code = getElem('matlab');
    schema = getElem('schema');
    json = getElem('json');

    status = '';

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    fprintf(1, ' stringify ... ');
    [jsonOut, errors] = JSON_Stringifier.stringify(a, schema, 0);
    if ~isempty(errors)
        status = ':x: ';
        errors
    end

    if ~strcmp(regexprep(json, '\s', ''), jsonOut)
        status = ':x: ';
        json
        jsonOut
    end

    fprintf(1, ' parse ... ');
    [objOut, errors] = JSON_Parser.parse(json, schema);
    if ~isempty(errors)
        status = ':x: ';
        errors
    end

    if ~isequaln(a, objOut)
        status = ':x: ';
        a
        objOut
    end

    append('| %s%s |', status, desc);
    append('| %s | %s | %s |', nl(code), nl(schema), nl(json));

end

fclose(fid);

end
