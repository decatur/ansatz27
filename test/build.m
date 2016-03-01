addpath('../lib');
%debug_on_error(true);

testRoundtrip();
testStringify();
testParse();
testValidation();

testMisc();

% README.md must be ASCII!

%readme = JSON_Handler.readFileToString('../README.md', 'latin1');
%readme = strPartRep(readme, 'ROUNDTRIP', errorMarkup);
%readme = strPartRep(readme, 'VALIDATION', errorMarkup);






