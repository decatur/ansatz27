function testParse(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testParse.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');

fid = fopen(fullfile(dir, '..', 'build', 'parse.html'), 'w');
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

    expected = a;

    [actual, errors] = JSON_Parser.parse(json, schema);

    appendRow(fid, '<td span="3">%s</td>', desc);
    appendRow(fid, repmat('<td><pre>%s</pre></td>', 1, 3), code, schema, json);

    if ~isempty(errors)
        errors
    end

    if ~isequal(expected, actual)
        expected
        actual
    end

end

fprintf(fid, '</tbody></table>');
fclose(fid);

end
