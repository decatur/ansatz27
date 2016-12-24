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
        
        function _exec(this, testname)
            
            subDirs = dir(this.absdir);
            subDirs = subDirs(3:end);   % Omit . and ..
            
            for k=1:length(subDirs)
                if exist('testname', 'var') == 0 || isequal(testname, subDirs(k).name)
                    prevCount = this.errorCount;
                    tic();
                    fprintf(1, '########## %s ##########\n',  subDirs(k).name);
                    this.execSingle(subDirs(k).name);
                    if prevCount == this.errorCount
                        fprintf(1, 'OK in %g[sec]\n', toc());
                    else
                        fprintf(1, 'Failure in %g[sec]\n', toc());
                    end
                end
            end
        end
        
    end
    
end