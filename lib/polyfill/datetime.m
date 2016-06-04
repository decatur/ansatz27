% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef datetime < handle
% Polyfill for the datetime class for Octave and pre MATLAB 2014.
% Implemented is a very small subset needed to successfully run the JSON test cases. 

    properties
        Format      % The format used to convert the date to char array
    end

    properties %(SetAccess = immutable)
        TimeZone    % We represent TimeZone agnostic dates in the UTC Timezone
        Year
        Month       % Month of the year in the range 1:12
        Day         % Day of the month in the range 1:31
        Hour        % Hour of the day in the range 0:23
        Minute      % Minute within the hour in the range 0:59
        Second      % Second within the minute in the range 0:59
    end

    properties (Access = private)
        _millis       % epoch millis.
    end

    methods

        function this = datetime(varargin)
            % Usage:
            %  datetime('2014-01-01T01:02+0100', 'TimeZone', '+0100', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssZ')

            if nargin == 0
                error();
            end

            k = 1;

            if isnumeric(varargin{1})
                this.Year   = varargin{1};
                this.Month  = varargin{2};
                this.Day    = varargin{3};
                this.Hour   = varargin{4};
                this.Minute = varargin{5};
                this.Second = varargin{6};
                k = 7;
            elseif ischar(varargin{1})
                dateStr = varargin{1};
                k = 2;
            else
                error('Invalid first argument to datetime')
            end

            this.TimeZone = '';
            infmt = 'yyyy-MM-dd';

            for k = k:2:length(varargin)-1
                param = varargin{k};
                if strcmp('InputFormat', param)
                    infmt = varargin{k+1};
                elseif strcmp('TimeZone', param)
                    this.TimeZone = varargin{k+1};
                elseif strcmp('Format', param)
                    this.Format = varargin{k+1};
                else
                    error('Argument not supported: %s', param)
                end
            end

            if strcmp(this.Format, 'preserveinput') || isempty(this.Format)
                this.Format = infmt;
            end

            tz = javaMethod('getTimeZone', 'java.util.TimeZone', this._getTimeZone());
            cal = javaMethod('getInstance', 'java.util.Calendar', tz);

            if isnumeric(varargin{1})
                cal.clear(cal.MILLISECOND);
                cal.set(cal.YEAR, this.Year);
                cal.set(cal.MONTH, this.Month-1);
                cal.set(cal.DAY_OF_MONTH, this.Day);
                cal.set(cal.HOUR_OF_DAY, this.Hour);
                cal.set(cal.MINUTE, this.Minute);
                cal.set(cal.SECOND, this.Second);
                this._millis = cal.getTime().getTime();
                return
            end

            errFormat = 'Unable to parse date/time string ''%s'' using the format ''%s''.';

            %if isequal(infmt, 'yyyy-MM-dd') && length(dateStr) ~= 10
            %     error(errFormat, dateStr, infmt);
            %end

            try
                sdf = javaObject('java.text.SimpleDateFormat', infmt);
            catch e
                error('Invalid format %s', infmt);
            end

            sdf.setTimeZone(tz);

            try
                date = sdf.parse(dateStr);
            catch e
                error(errFormat, dateStr, infmt);
            end

            cal.setTime(date);
            this.Year = cal.get(cal.YEAR);
            this.Month = 1 + cal.get(cal.MONTH);
            this.Day = cal.get(cal.DAY_OF_MONTH);
            this.Hour = cal.get(cal.HOUR_OF_DAY);
            this.Minute = cal.get(cal.MINUTE);
            this.Second = cal.get(cal.SECOND);
            this._millis = date.getTime();
        end

        function b = isequal(this, other)
            b = ( isa(other, 'datetime') && this._millis == other._millis );
        end

        function b = isequaln(this, other)
            b = isequal(this, other);
        end

        function dateStr = char(this)
            tz = javaMethod('getTimeZone', 'java.util.TimeZone', this._getTimeZone());
            sdf = javaObject('java.text.SimpleDateFormat', this.Format);
            sdf.setTimeZone(tz);
            dateStr = char(sdf.format(javaObject('java.util.Date', this._millis)));
        end

        function dateStr = datestr(this)
            dateStr = char(this);
        end

        function disp(this)
            display(char(this));
        end

        function n = datenum(this)
            n = datenum(this.Year, this.Month, this.Day, this.Hour, this.Minute, this.Second);
        end

        function dt = plus(a, b)
            if isa(b, 'datetime')
                dt = b;
                days = a;
            else
                dt = a;
                days = b;
            end

            tz = javaMethod('getTimeZone', 'java.util.TimeZone', dt._getTimeZone());
            cal = javaMethod('getInstance', 'java.util.Calendar', tz);
            cal.setTime(javaObject('java.util.Date', dt._millis));
            cal.add(cal.SECOND, days*24*60*60);
            dt = datetime(cal.get(cal.YEAR), 1 + cal.get(cal.MONTH), cal.get(cal.DAY_OF_MONTH), cal.get(cal.HOUR_OF_DAY), cal.get(cal.MINUTE), cal.get(cal.SECOND), 'TimeZone', dt.TimeZone);
        end

        function zone = _getTimeZone(this)
            zone = 'UTC';
            if ~isempty(this.TimeZone)
                zone = this.TimeZone;
            end
        end

    end

end
