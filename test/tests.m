%actual

clear classes

if JSON.isoct
    addpath('lib/polyfill', '-end');
    debug_on_error(true);
end

testMisc;
testContainersMap;

testUsage;
testErrorHandling;

testTestCase;
testDatetime;

TestRoundtrip().exec();
TestStringify().exec();
TestParse().exec();
TestValidation().exec();

