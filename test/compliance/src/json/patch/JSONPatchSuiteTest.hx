package json.patch;

import json.patch.JSONPatch;

class JSONPatchSuiteTest
{
	public static function test():Void
	{
		var queries:Array<TestQuery> = parseSuiteData('spec_tests');
		testSuite(queries);

        var queries:Array<TestQuery> = parseSuiteData('tests');
        testSuite(queries);

		trace('JSONPatchTest: Done.');
	}

    public static function testQuery(query:TestQuery):Bool {
        var doc = query.doc;
        var patch = query.patch;

        var shouldError = query.error != null;

        try {
            var result = JSONPatch.applyPatches(doc, patch);
            if (shouldError) {
                trace('FAILURE - ${query.comment}');
                trace('  Got no error, expected "${query.error}"');
                return false;
            } else {
                var expected = query.expected;
                if (!thx.Dynamics.equals(result, expected)) {
                    trace('FAILURE - ${query.comment}');
                    trace('  Got ${result}, expected ${expected}');
                    return false;
                } else {
                    trace('SUCCESS - ${query.comment}');
                    return true;
                }
            }
        } catch (e) {
            if (shouldError) {
                // Don't validate error message.
                trace('SUCCESS - ${query.comment}');
                return true;
            } else {
                throw e;
            }
        }
    }

    public static function testSuite(queries:Array<TestQuery>):Void{
        trace('===TESTS===');
		trace('Testing ${queries.length} queries...');

		var successes = 0;
		var failures = 0;
		var errors = 0;
		var skipped = 0;
		for (query in queries) {
            if (query.disabled) {
                trace('DISABLED - ${query.comment}');
                skipped++;
                continue;
            }
            try
            {
                var result = testQuery(query);
                if (result)
                    successes++;
                else
                    failures++;
            } catch (e) {
                if ('$e' == "INVALID TEST") {
                    trace('INVALID - ${query.comment}');
                    errors++;
                } else if ('$e' == "SKIPPED TEST") {
                    trace('SKIPPED - ${query.comment}');
                    skipped++;
                } else {
                    trace('ERROR - ${query.comment}');
                    trace('  ${e}');
                    errors++;
                }
            }
        }
    
        trace('===RESULTS===');
        trace('Successes: ${successes}');
        trace('Failures: ${failures}');
        trace('Errors: ${errors}');
        trace('Skipped: ${skipped}');
    }

	static function parseSuiteData(key:String):Array<TestQuery>
	{
		var testDataStr:String = sys.io.File.getContent('../../json-patch-tests/$key.json');
		var testData:JSONData = JSONData.parse(testDataStr);

		var tests:Array<JSONData> = testData;

		var queries:Array<TestQuery> = [];
		for (test in tests)
		{
            switch (test.getData('comment')) {
                // case "test with bad number should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                // case "test remove with bad index should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                // case "test remove with bad number should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                // case "test copy with bad number should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                // case "test move with bad number should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                // case "test add with bad number should fail":
                    // Ignore tests which get particular about strings like "1e0"
                    // continue;
                default:
                    // Do nothing
            }

			var query:TestQuery = {
				comment: test.getData('comment'),
				doc: test.getData('doc'),
				patch: test.getData('patch'),

                expected: test.getData('expected'),
                error: test.getData('error'),
                disabled: test.getData('disabled'),
			};
			queries.push(query);
		}

		return queries;
	}
}

typedef TestQuery = {
    var comment: String;
    var doc: JSONData;
    var patch: JSONData;

    var ?expected: JSONData;
    var ?error: String;
    var ?disabled: Bool;
}