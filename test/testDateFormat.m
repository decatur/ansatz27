addpath('../lib');

s = JSON_Handler.datenum2string(736368);
assert(strcmp(s, '2016-02-08'));

s = JSON_Handler.datenum2string(736368.5);
assert(s == 736368.5);

n_12_30_30 = 1/2 + 1/24/60*(30+1/2);

s = JSON_Handler.datetimenum2string(736368 + n_12_30_30);
assert(strcmp(s, '2016-02-08T12:30:30Z'));


n = JSON_Handler.datestring2num('2016-02-08');
assert(n == 736368);

n = JSON_Handler.datestring2num('2016-02-08T12:00Z');
assert(strcmp(n, '2016-02-08T12:00Z'));

n = JSON_Handler.datestring2num('2016-02-08 12:00Z');
assert(strcmp(n, '2016-02-08 12:00Z'));

n = JSON_Handler.datetimestring2num('2016-02-08T12Z');
assert(n == 736368.5);

n = JSON_Handler.datetimestring2num('2016-02-08T12+0000');
assert(n == 736368.5);

n = JSON_Handler.datetimestring2num('2016-02-08T13+0100');
assert(n == 736368.5);

n = JSON_Handler.datetimestring2num('2016-02-08T12:30:30Z');
assert(n == 736368 + n_12_30_30);

n = JSON_Handler.datetimestring2num('2016-02-08T13:00+foo');
assert(strcmp(n, '2016-02-08T13:00+foo'));