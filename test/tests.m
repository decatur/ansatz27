addpath('lib', 'test');
addpath('lib/polyfill', '-end');

if JSON.isoct
    debug_on_error(true);
end

testRoundtrip();
testStringify();
testParse();
testValidation();
testMisc;
testDateFormat;







