% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function [ date_num ] = datetime( date_str )
% TODO: This function should not shadow MATLABs datetime()

formatString = 'yyyy-MM-dd';

if (ischar(date_str) && isempty(regexp(date_str, '^\d{4}-\d{2}-\d{2}$'))) || ...
    (isnumeric(date_str) && rem(date_str, 1) ~=0 )
    formatString = [formatString '''T''HH:mmZ'];
end

isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;

if isoct
    format = javaObject('java.text.SimpleDateFormat' ,formatString);
else
    format = java.text.SimpleDateFormat(formatString);
end

millisPerDay = 1000*60*60*24;

if ischar(date_str)
    date_num = 719529 + format.parse(date_str).getTime()/millisPerDay;
else
    d = javaObject('java.util.Date' , (date_str-719529)*millisPerDay);
    date_num = format.format(d);
end

end

