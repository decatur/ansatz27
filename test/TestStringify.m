classdef TestStringify < TestBase

    methods

        function this = TestStringify()
            this@TestBase('testStringify.xml');
        end

        function execSingle(this, test)
            matlab = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            jsonExpected = this.getElementText(test, 'json');

            [jsonActual, errors] = JSON.stringify(matlab, schema, 0);

            this.assertEmpty(errors);
            this.assertEqual(jsonActual, jsonExpected);
        end

    end % methods
end

