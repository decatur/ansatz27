classdef TestValidation < TestBase

    methods

        function this = TestValidation()
            this@TestBase('validation');
        end

        function errors = stripErrorCode(this, errors)
            for l=1:length(errors)
                errors{l} = errors{l}(1:end-1);
            end
        end

        function execSingle(this, dirName)
            dirPath = fullfile(this.absdir, dirName);
            dirUrl = ['file:///' strrep(dirPath, '\', '/')];
            schemaURL = [dirUrl '/schema.json'];
            
            

            path = fullfile(dirPath, 'payload.m');
            if exist(path, 'file') ~= 0
                expectedMatlab = eval(urlread([dirUrl '/payload.m']));
            else
                expectedMatlab = [];
            end
            
            expectedJSON = urlread([dirUrl '/payload.json']);
            
            expectedErrors = urlread([dirUrl '/errors.m']);
            expectedErrors = eval(expectedErrors);
            for l=1:length(expectedErrors)
                expectedErrors{l}(2) = strrep (expectedErrors{l}(2), 'BASE', dirUrl);
            end


            if ~isempty(expectedMatlab)
                fprintf(1, 'stringify\n');
                [jsonActual, actualErrors] = JSON.stringify(expectedMatlab, schemaURL, 0);
                this.assertEqual(this.stripErrorCode(actualErrors), expectedErrors);
            end

            if ~isempty(expectedJSON)
                fprintf(1, 'parse\n');
                [actualMatlab, actualErrors] = JSON.parse(expectedJSON, schemaURL);
                this.assertEqual(this.stripErrorCode(actualErrors), expectedErrors);
            end

        end

    end % methods

end
