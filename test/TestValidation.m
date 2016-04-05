classdef TestValidation < TestBase

    methods

        function this = TestValidation()
            this@TestBase('testValidation.xml');
        end

        function execSingle(this, test)

            matlab = this.getElementText(test, 'matlab');
            schema = this.getElementText(test, 'schema');
            jsonExpected = this.getElementText(test, 'json');
            errorText = this.getElementText(test, 'errors');
            expectedErrors = eval(['{' strrep(errorText, sprintf('\n'), ' ') '}']);
            
            if ~isempty(matlab)
                [jsonActual, actualErrors] = JSON.stringify(matlab, schema, 0);
                for l=1:length(actualErrors)
                    actualErrors{l} = actualErrors{l}(1:end-1);
                end
            
                this.assertEqual(actualErrors, expectedErrors);
            end

            if ~isempty(jsonExpected)
                fprintf(1, '\t\tparse ... ');
                [actualMatlab, actualErrors] = JSON.parse(jsonExpected, schema);
                for l=1:length(actualErrors)
                    actualErrors{l} = actualErrors{l}(1:end-1);
                end
                this.assertEqual(actualErrors, expectedErrors);
            end

        end

    end % methods

end
