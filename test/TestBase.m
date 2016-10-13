classdef TestBase < TestCase
    
    properties
        testType
        absdir
    end
    
    methods
        
        function this = TestBase(testType)
            this.testType = testType;
            this.absdir = fullfile(pwd(), this.testType);
            this.absdir = strrep(this.absdir, '\', '/');
        end
        
        function exec(this, testname)
            %document = xmlread(fullfile(this.absdir, this.fileName));
            %tests = document.getDocumentElement().getElementsByTagName('test');
            
            subDirs = dir(this.absdir);
            subDirs = subDirs(3:end);   % Omit . and ..
            
            for k=1:length(subDirs)
                if exist('testname', 'var') == 0 || isequal(testname, subDirs(k).name)
                    this.errorCount = 0;
                    tic();
                    fprintf(1, '########## %s ##########\n',  subDirs(k).name);
                    this.execSingle(subDirs(k).name);
                    if ~this.errorCount
                        fprintf(1, 'OK in %g[sec]\n', toc());
                    else
                        fprintf(1, 'Failure in %g[sec]\n', toc());
                    end
                end
            end
            
            if this.errorCount > 0
                fprintf(1, 'There are %u errors\n', this.errorCount);
            end
        end
        
    end
    
end