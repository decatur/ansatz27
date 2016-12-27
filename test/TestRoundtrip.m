classdef TestRoundtrip < TestBase
    
    methods
        
        function this = TestRoundtrip()
            this@TestBase('roundtrip');
        end
        
        function execSingle(this, dirName)
            dirPath = fullfile(this.absdir, dirName);
            dirUrl = ['file:///' strrep(dirPath, '\', '/')];
            
            mCode = urlread([dirUrl '/payload.m']);
            if 1 == regexp(mCode, '^\s*a\s*=')
                % Prevent: Attempt to add "a" to a static workspace.
                a = [];
                eval(mCode);
                expectedMatlab = a;
            else
                expectedMatlab = eval(mCode);
            end
            
            if exist(fullfile(dirPath, 'schema.json'), 'file') == 0
                schemaURL = [];
            else
                schemaURL = [dirUrl '/schema.json'];
            end
            
            jsonURL = [dirUrl '/payload.json'];
            expectedJSON = urlread(jsonURL);
            
            fprintf(1, 'stringify\n');
            
            [actualJSON, errors] = JSON.stringify(expectedMatlab, schemaURL, 0);
            this.assertEmpty(errors);
            this.assertEqual(regexprep(actualJSON, '\s', ''), regexprep(expectedJSON, '\s', ''));
            
            fprintf(1, 'parse\n');
            [actualMatlab, errors] = JSON.parse(expectedJSON, schemaURL);
            this.assertEmpty(errors);
            this.assertEqual(actualMatlab, expectedMatlab);
        end
        
    end % methods
    
end
