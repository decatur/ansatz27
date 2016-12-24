% Run this script within the containing directory.

inittests;

testContainersMap;
testUsage;
testErrorHandling;
testDatetime;

% Run a single test with tc.exec('Reuse_with_Schema_References');

suite = TestSuite();
suite.add(TestMisc());
suite.add(TestRoundtrip());
suite.add(TestStringify());
suite.add(TestParse());
suite.add(TestValidation());

suite.exec();
