function testRoundtrip(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testRoundtrip.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');

fid = fopen (fullfile(dir, '../build/roundtrip.html'), 'w');
fprintf(fid, '<table><tbody valign="top">\n');
appendRow(fid, '<th>MATLAB</th><th>Schema</th><th>JSON</th>');

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

    appendRow(fid, '<td span="3">%s %s</td>', status, desc);
    appendRow(fid, repmat('<td><pre>%s</pre></td>', 1, 3), code, schema, jsonExpected);

end

fprintf(fid, '</tbody></table>');
fclose(fid);

end
