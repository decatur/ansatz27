% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef Datetime < handle

    properties (Constant)
    end

    properties %(Access = private)
        TimeZone % +01:00
        num
    end
    
    methods

        function this = Datetime(x)
            if nargin < 1
                this.num = now;
            elseif isnumeric(x)
                this.num = x;
            elseif ischar(x)
                this.num = JSON.datestring2num(x);
            end
        end

        function toString
        % 04-Mar-2016 20:01:28
        end

        function n = datenum(this)
        % t = datetime('2014-01-01T01:02:03', 'TimeZone', '+01:00', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss')
        % datenum(t)
        % ans = 7.3639e+05
            parts = strsplit(this.TimeZone, ':');
            n = this.num + (str2double(parts{1}) + str2double(parts{1})/60)/24;
        end

    end

    methods (Static)
        
    end
end
