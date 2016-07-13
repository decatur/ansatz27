classdef TestValidation < TestBase

    methods

        function this = TestValidation()
            this@TestBase('validation');
        end

        function execSingle(this, dirName)
            dirPath = fullfile(this.absdir, dirName);
            dirUrl = ['file:///' strrep(dirPath, '\', '/')];
            schemaURL = [dirUrl '/schema.json'];
            
            path = fullfile(dirPath, 'payload.m');
            if exist(path, 'file') ~= 0
                run(fullfile(dirPath, 'payload.m'));
                matlab = a;
            else
                matlab = [];
            end
            
            expectedJSON = urlread([dirUrl '/payload.json']);
            
            expectedErrors = urlread([dirUrl '/errors.m']);
            expectedErrors = eval(expectedErrors);

            if ~isempty(matlab)
                fprintf(1, 'stringify\n');
                [jsonActual, actualErrors] = JSON.stringify(matlab, schemaURL, 0);
                for l=1:length(actualErrors)
                    actualErrors{l} = actualErrors{l}(1:end-1);
                end
            
                this.assertEqual(actualErrors, expectedErrors);
            end

            if ~isempty(expectedJSON)
                fprintf(1, 'parse\n');
                [actualMatlab, actualErrors] = JSON.parse(expectedJSON, schemaURL);
                for l=1:length(actualErrors)
                    actualErrors{l} = actualErrors{l}(1:end-1);
                end
                this.assertEqual(actualErrors, expectedErrors);
            end

        end

    end % methods

end
