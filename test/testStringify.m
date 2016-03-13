function testStringify(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testStringify.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

fid = fopen(fullfile(dir, '..', 'build', 'stringify.md'), 'w');

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    jsonExpected = getElementText(test, 'json');

    if isempty(regexp(code, '^a\s*='))
        a = eval(code);
    else
        eval(code);
    end

    [jsonActual, errors] = JSON_Stringifier.stringify(a, schema, 0);

    if strcmp(char(test.getAttribute('readme')), 'true')
        fprintf(fid, '### %s\n', desc);
        fprintf(fid, 'MATLAB\n```MATLAB\n%s\n```\n', code);
        fprintf(fid, 'JSON\n```JSON\n%s\n```\n\n', jsonExpected);
        fprintf(fid, 'Schema\n```JSON\n%s\n```\n', schema);
    end

    tc.assertEmpty(errors);
    tc.assertEqual(jsonActual, jsonExpected);

end

fclose(fid);

end

