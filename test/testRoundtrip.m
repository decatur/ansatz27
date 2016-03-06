function testRoundtrip(description)

fid = fopen ('../build/roundtrip.html', 'w');

function append(format, varargin)
    fprintf(fid, ['<tr>' format '</tr>\n'], varargin{:});
end

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', 'testRoundtrip.xml');
document = builder.parse(file);

tests = document.getDocumentElement().getElementsByTagName('test');
nl = @(text) text;

fprintf(fid, '<table><tbody>\n');
append('<th>MATLAB</th><th>Schema</th><th>JSON</th>');

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '\n%s', desc);

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    jsonExpected = getElementText(test, 'json');

    status = '(Pass)';

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    fprintf(1, ' ... stringify ');
    [jsonActual, errors] = JSON_Stringifier.stringify(a, schema, 0);
    if ~isempty(errors)
        status = 'Fail';
        errors
    end

    if ~strcmp(regexprep(jsonExpected, '\s', ''), jsonActual)
        status = 'Fail';
        jsonExpected
        jsonActual
    end

    fprintf(1, ' ... parse ');
    [actualM, errors] = JSON_Parser.parse(jsonExpected, schema);
    if ~isempty(errors)
        status = 'Fail';
        errors
    end

    expectedM = a;

    if ~isequaln(expectedM, actualM) || (islogical(expectedM) && ~islogical(actualM))
        status = 'Fail';
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

    append('<td span="3">%s %s</td>', status, desc);
    append('<td><pre>%s</pre></td><td><pre>%s</pre></td><td><pre>%s</pre></td>', nl(code), nl(schema), nl(jsonExpected));

end

fprintf(fid, '</tbody></table>');
fclose(fid);

end
