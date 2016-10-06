classdef TestStringify < TestBase

    methods

        function this = TestStringify()
            this@TestBase('stringify');
        end

        function execSingle(this, dirName)
            dirPath = fullfile(this.absdir, dirName);
            dirUrl = ['file:///' strrep(dirPath, '\', '/')];
            
            expectedMatlab = eval(urlread([dirUrl '/payload.m']));

            if exist(fullfile(dirPath, 'schema.json'), 'file') == 0
                schemaURL = [];
            else
                schemaURL = [dirUrl '/schema.json'];
            end
            
            expectedJSON = urlread([dirUrl '/payload.json']);

            fprintf(1, 'stringify\n');
            
            [actualJSON, errors] = JSON.stringify(expectedMatlab, schemaURL, 0);
            this.assertEmpty(errors);
            this.assertEqual(regexprep(actualJSON, '\s', ''), regexprep(expectedJSON, '\s', ''));
        end

    end % methods
end

