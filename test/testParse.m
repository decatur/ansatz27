function testParse(description)

dir = fileparts(mfilename ("fullpath"));

document = xmlread(fullfile(dir, 'testParse.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

fid = fopen(fullfile(dir, '..', 'build', 'parse.md'), 'w');

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

    expectedMatlab = a;

    [actualMatlab, errors] = JSON.parse(json, schema);

    if strcmp(char(test.getAttribute('readme')), 'true')
        fprintf(fid, '### %s\n', desc);
        fprintf(fid, 'MATLAB\n```MATLAB\n%s\n```\n', code);
        fprintf(fid, 'JSON\n```JSON\n%s\n```\n\n', json);
        fprintf(fid, 'Schema\n```JSON\n%s\n```\n', schema);
    end

    tc.assertEmpty(errors);
    tc.assertEqual(actualMatlab, expectedMatlab);

end

fclose(fid);

end
