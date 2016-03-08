function testStringify(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testStringify.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');

fid = fopen(fullfile(dir, '..', 'build', 'stringify.html'), 'w');
fprintf(fid, '<table><tbody valign="top">\n');
appendRow(fid, '<th>MATLAB</th><th>Schema</th><th>JSON</th>');

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    json = getElementText(test, 'json');

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    [jsonOut, errors] = JSON_Stringifier.stringify(a, schema, 0);

    appendRow(fid, '<td colspan="3">%s</td>', desc);
    appendRow(fid, repmat('<td><pre>%s</pre></td>', 1, 3), code, schema, json);

    assert(isempty(errors));

    if ~strcmp(json, jsonOut)
        keyboard
        fprintf(1, 'Expected: %s\n', json);
        fprintf(1, 'Actual: %s\n', jsonOut);
    end

end

fprintf(fid, '</tbody></table>');
fclose(fid);

end

