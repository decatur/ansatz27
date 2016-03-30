classdef TestStringify < TestBase

    methods

        function this = TestParse()
            this@TestBase('testStringify.xml');
        end

        function execSingle(this, test)
            code = getElementText(test, 'matlab');
            schema = getElementText(test, 'schema');
            jsonExpected = getElementText(test, 'json');

            if isempty(regexp(code, '^a\s*=', 'once'))
                a = eval(code);
            else
                eval(code);
            end

            [jsonActual, errors] = JSON_Stringifier.stringify(a, schema, 0);

            this.assertEmpty(errors);
            this.assertEqual(jsonActual, jsonExpected);
        end

    end % methods
end

