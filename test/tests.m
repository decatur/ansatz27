addpath('lib', 'test');
addpath('lib/polyfill', '-end');

if JSON.isoct
    debug_on_error(true);
end

tc = TestRoundtrip();     tc.exec();
tc = TestStringify();     tc.exec();
tc = TestParse();         tc.exec();
tc = TestValidation();    tc.exec();

testMisc;
testDateFormat;
testContainersMap;







