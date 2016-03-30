classdef TestParse < TestBase

    methods

        function this = TestParse()
            this@TestBase('testParse.xml');
        end

        function execSingle(this, test)
            code = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            json = this.getElementText(test, 'json');

            if ~isempty(json)
                if isempty(regexp(code, '^a\s*=', 'once'))
                    a = eval(code);
                else
                    eval(code);
                end

                expectedMatlab = a;

                [actualMatlab, errors] = JSON.parse(json, schema);

                this.assertEmpty(errors);
                this.assertEqual(actualMatlab, expectedMatlab);
            end

        end

    end % methods

end
