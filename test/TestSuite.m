% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef TestSuite < handle
    
    properties
        testCases
    end
    
    methods (Access=public)

        function this = TestSuite()
            this.testCases = {};
        end

        function exec(this)
            fprintf(1, 'Running test suite with %d cases\n', length(this.testCases));
            totalErrorCount = 0;
            
            for k=1:length(this.testCases)
                tc = this.testCases{k};
                tc.exec();
                totalErrorCount = totalErrorCount + tc.errorCount
            end

            if totalErrorCount > 0
                fprintf(1, 'There are %u errors\n', totalErrorCount);
            else
                fprintf(1, 'No errors\n');
            end
        end

        function add(this, tc)
            this.testCases{end+1} = tc;
        end
        
    end % methods

end
