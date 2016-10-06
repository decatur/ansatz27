classdef TestParse < TestBase

    methods

        function this = TestParse()
            this@TestBase('parse');
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

            fprintf(1, 'parse\n');
            [actualMatlab, errors] = JSON.parse(expectedJSON, schemaURL);
            this.assertEmpty(errors);
            this.assertEqual(actualMatlab, expectedMatlab);
        end

    end % methods

end
