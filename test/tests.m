addpath('lib', 'test');
addpath('lib/polyfill', '-end');

if JSON.isoct
    debug_on_error(true);
end

TestRoundtrip().exec();
TestStringify().exec();
TestParse().exec();
TestValidation().exec();

testMisc;
testDateFormat;
testContainersMap;
