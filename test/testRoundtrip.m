function testRoundtrip(description)

dir = fileparts(mfilename ('fullpath'));

document = xmlread(fullfile(dir, 'testRoundtrip.xml'));
tests = document.getDocumentElement().getElementsByTagName('test');
tc = TestCase();

for k=1:tests.getLength()
    test = tests.item(k-1);
    
    desc = getElementText(test, 'description');
    if nargin >= 1 && ~strcmp(desc, description)
        continue;
    end

    fprintf(1, '%s', desc);

    if strcmp(test.getAttribute('skip'), 'true')
        fprintf(1, '\t\tSkipping\n');
        continue;
    end

    code = getElementText(test, 'matlab');
    schema = getElementText(test, 'schema');
    expectedJSON = getElementText(test, 'json');

    if isempty(regexp(code, '^a\s*=', 'once'))
        a = eval(code);
    else
        eval(code);
    end

    expectedMatlab = a;

    fprintf(1, '\t\tstringify ... ');
    [actualJSON, errors] = JSON.stringify(a, schema, 0);
    tc.assertEmpty(errors);
    tc.assertEqual(regexprep(actualJSON, '\s', ''), regexprep(expectedJSON, '\s', ''));

    fprintf(1, '\t\tparse ... ');
    [actualMatlab, errors] = JSON.parse(expectedJSON, schema);
    tc.assertEmpty(errors);
    tc.assertEqual(actualMatlab, expectedMatlab);
    tc.assertEqual(islogical(actualMatlab), islogical(expectedMatlab));

    fprintf(1, 'OK\n');
end

end
