classdef TestRoundtrip < TestBase

    methods

        function this = TestRoundtrip()
            this@TestBase('testRoundtrip.xml');
        end

        function execSingle(this, test, desc)
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

        end

    end % methods

end
