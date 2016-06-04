tc = TestCase();
tc.assertEqual(1, 1);

tc.assertEqual(struct('a',2), struct('a',2))

m1 = containers.Map;
m2 = containers.Map;
tc.assertEqual(m1, m2);

m1('a') = 3;
m2('a') = 3;
tc.assertEqual(m1, m2);

dt1 = datetime('2016-01-01');
dt2 = datetime('2016-01-01');

tc.assertEqual(dt1, dt2);