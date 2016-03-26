function testParse(description)

dir = fileparts(mfilename ('fullpath'));

document = xmlread(fullfile(dir, 'testParse.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '%s ... ', desc);

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    json = getElementText(test, 'json');

    if ~isempty(json)
        if isempty(regexp(code, '^a\s*=', 'once'))
            a = eval(code);
        else
            eval(code);
        end

        expectedMatlab = a;

        [actualMatlab, errors] = JSON.parse(json, schema);

        tc.assertEmpty(errors);
        tc.assertEqual(actualMatlab, expectedMatlab);
    end

    fprintf(1, 'OK\n');

end

end
