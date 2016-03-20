function testStringify(description)

dir = fileparts(mfilename ('fullpath'));

document = xmlread(fullfile(dir, 'testStringify.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

for k=1:tests.getLength()
    test = tests.item(k-1);

    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    jsonExpected = getElementText(test, 'json');

    if isempty(regexp(code, '^a\s*=', 'once'))
        a = eval(code);
    else
        eval(code);
    end

    [jsonActual, errors] = JSON_Stringifier.stringify(a, schema, 0);

    tc.assertEmpty(errors);
    tc.assertEqual(jsonActual, jsonExpected);

end

end

