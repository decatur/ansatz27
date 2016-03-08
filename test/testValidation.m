function testValidation(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testValidation.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');

fid = fopen(fullfile(dir, '..', 'build', 'validation.html'), 'w');
fprintf(fid, '<table><tbody valign="top">\n');
appendRow(fid, '<th>MATLAB</th><th>JSON</th><th>Schema</th><th>Errors</th>');

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

    appendRow(fid, '<td colspan="4">%s</td>', desc);
    appendRow(fid, repmat('<td><pre>%s</pre></td>', 1, 4), code, json, schema, errorText);

    expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    [jsonOut, errors] = JSON.stringify(a, schema, 0);

    if ~isequal(expectedErrors, errors)
        fprintf(1, 'stringify\n');
        expectedErrors
        errors
    end

    [objOut, errors] = JSON.parse(json, schema);

    if ~isequal(expectedErrors, errors)
        fprintf(1, 'parse\n');
        expectedErrors
        errors
    end

end

fprintf(fid, '</tbody></table>');
fclose(fid);

end
