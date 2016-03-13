addpath('lib', 'test');

%if 5~=exist('DateTime', 'builtin')
    addpath('lib/polyfill', '-end');
%end

debug_on_error(true);

testRoundtrip();
testStringify();
testParse();
testValidation();
testMisc;
testDateFormat;
testUsage;







