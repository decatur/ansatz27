classdef TestBase < TestCase
    
    properties
        testType
        absdir
    end
    
    methods
        
        function this = TestBase(testType)
            this.testType = testType;
            this.absdir = fullfile(pwd(), 'testcases', this.testType);
            this.absdir = strrep(this.absdir, '\', '/');
        end
        
        function exec(this)
            %document = xmlread(fullfile(this.absdir, this.fileName));
            %tests = document.getDocumentElement().getElementsByTagName('test');
            
            subDirs = dir(this.absdir);
            subDirs = subDirs(3:end);   % Omit . and ..
            
            for k=1:length(subDirs)
                fprintf(1, '########## %s ##########\n',  subDirs(k).name);
                tic();
                this.execSingle(subDirs(k).name);
                fprintf(1, 'OK in %g[sec]\n', toc());
            end
            
            if this.errorCount > 0
                fprintf(1, 'There are %u errors\n', this.errorCount);
            end
        end
        
    end
    
end