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
    jsonExpected = getElem('json');

    status = ':white_check_mark:';

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    fprintf(1, ' ... stringify ');
    [jsonActual, errors] = JSON_Stringifier.stringify(a, schema, 0);
    if ~isempty(errors)
        status = ':x:';
        errors
    end

    if ~strcmp(regexprep(jsonExpected, '\s', ''), jsonActual)
        status = ':x:';
        jsonExpected
        jsonActual
    end

    fprintf(1, ' ... parse ');
    [actualM, errors] = JSON_Parser.parse(jsonExpected, schema);
    if ~isempty(errors)
        status = ':x:';
        errors
    end

    expectedM = a;

    if ~isequaln(expectedM, actualM) || (islogical(expectedM) && ~islogical(actualM))
        status = ':x:';
        if isnumeric(expectedM) || islogical(expectedM) 
            mat2str(expectedM)
        else
            expectedM
        end

        if isnumeric(actualM) || islogical(actualM)
            mat2str(actualM)
        else
            actualM
        end

    end

    append('| %s %s |', status, desc);
    append('| %s | %s | %s |', nl(code), nl(schema), nl(jsonExpected));

end

fclose(fid);

end
