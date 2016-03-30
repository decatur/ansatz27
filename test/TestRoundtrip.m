classdef TestRoundtrip < TestBase

    methods

        function this = TestRoundtrip()
            this@TestBase('testRoundtrip.xml');
        end

        function execSingle(this, test)
            code = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            expectedJSON = this.getElementText(test, 'json');

            if isempty(regexp(code, '^a\s*=', 'once'))
                a = eval(code);
            else
                eval(code);
            end

            expectedMatlab = a;

            fprintf(1, '\t\tstringify ... ');
            [actualJSON, errors] = JSON.stringify(a, schema, 0);
            this.assertEmpty(errors);
            this.assertEqual(regexprep(actualJSON, '\s', ''), regexprep(expectedJSON, '\s', ''));

            fprintf(1, '\t\tparse ... ');
            [actualMatlab, errors] = JSON.parse(expectedJSON, schema);
            this.assertEmpty(errors);
            this.assertEqual(actualMatlab, expectedMatlab);
            this.assertEqual(islogical(actualMatlab), islogical(expectedMatlab));

        end

    end % methods

end
