function t = datetime(x, varargin)
% Example:
% t = datetime(now, 'TimeZone', '+01:00', 'ConvertFrom', 'datenum');
% 04-Mar-2016 20:01:28
% datetime('2014-01-01T01:02:03', 'TimeZone', '+01:00', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss')

t = Datetime(x);

for k=1:2:length(varargin)
    if strcmp(varargin{k}, 'TimeZone')
        t.TimeZone = varargin{k+1};
    end
end


