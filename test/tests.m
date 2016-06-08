% Run this script within the containing directory.

clear classes

if exist('datetime') ~= 2 || exist('containers.Map') ~= 8
    addpath('lib/polyfill', '-end');
end

if exist('debug_on_error')
    debug_on_error(true);
end
testMisc;
testContainersMap;

testUsage;
testErrorHandling;

%testTestCase;
%testDatetime;

tc = TestRoundtrip();   tc.exec();
tc = TestStringify();   tc.exec();
tc = TestParse();       tc.exec();
tc = TestValidation();  tc.exec();
