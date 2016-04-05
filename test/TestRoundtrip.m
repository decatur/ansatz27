classdef TestRoundtrip < TestBase

    methods

        function this = TestRoundtrip()
            this@TestBase('testRoundtrip.xml');
        end

        function execSingle(this, test)
            expectedMatlab = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            expectedJSON = this.getElementText(test, 'json');

            fprintf(1, '\t\tstringify ... ');
            
            [actualJSON, errors] = JSON.stringify(expectedMatlab, schema, 0);
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
