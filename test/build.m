addpath('../lib');
%debug_on_error(true);

testRoundtrip();
testStringify();
testParse();

markup = testErrors();

%testMisc();