classdef TestParse < TestBase

    methods

        function this = TestParse()
            this@TestBase('testParse.xml');
        end

        function execSingle(this, test)
            expectedMatlab = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            json = this.getElementText(test, 'json');

            if ~isempty(json)
                [actualMatlab, errors] = JSON.parse(json, schema);

                this.assertEmpty(errors);
                this.assertEqual(actualMatlab, expectedMatlab);
            end

        end

    end % methods

end
