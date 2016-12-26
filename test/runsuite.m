% Run this script within the containing directory.

inittests;

testUsage;
testErrorHandling;

suite = TestSuite();
suite.add(TestContainersMap());
suite.add(TestDatetime());
suite.add(TestMisc());

% Run a single test with tc.exec('Reuse_with_Schema_References');
suite.add(TestRoundtrip());
suite.add(TestStringify());
suite.add(TestParse());
suite.add(TestValidation());

suite.exec();
