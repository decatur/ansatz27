% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef datetime < handle

    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    end

    properties %(Access = private)
        TimeZone
        dateNum
    end
    
    methods

        function this = datetime(s)
            if nargin < 1
                this.dateNum = now
            else
                this.dateNum = JSON_Handler.datestring2num(s)
            end
        end

    end

    methods (Static)
        
    end
end

