% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef TestCase < handle

    properties (Constant)
    end

    properties %(Access = private)
    end
    
    methods

        function this = TestCase()
        end


        function assertEqual(this, actual, expected)
            msg = 'TestCase failed';
            if isempty(expected)
                if ~isempty(actual)
                    error(msg);
                end
            elseif ischar(expected)
                if ~ischar(actual) || ~strcmp(actual, expected)
                    error(msg);
                end
            else
                if ~isequaln(actual, expected)
                    error(msg);
                end
            end
        end

        function assertEmpty(this, actual)
            msg = 'TestCase failed';
            if ~isempty(actual)
                error(msg);
            end
        end

        
    end

    methods (Static)
    end
end
