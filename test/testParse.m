function testParse(description)

fid = fopen ('../build/parse.md', 'w');

function append(format, varargin)
    fprintf(fid, [format '\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', 'testParse.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) strrep(text, sprintf('\n'), '<br/>');

append('| MATLAB <-|<- Schema <-|<- JSON |');
append('|--------|--------|------|');

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    getElem = @(tagName) regexprep(strtrim(test.getElementsByTagName(tagName).item(0).getTextContent()), '\n\s{10}', '\n');

    desc = getElem('description');
    if nargin >= 1 && ~strcmp(desc, description)
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

    expected = a;

    [actual, errors] = JSON_Parser.parse(json, schema);

    append('| %s |', desc);
    append('| %s | %s | %s |', nl(code), nl(schema), nl(json));

    if ~isempty(errors)
        errors
    end

    if ~isequal(expected, actual)
        expected
        actual
    end

end


fclose(fid);

end
