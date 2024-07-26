package json.patch;

import json.patch.JSONPatch;

class JSONPatchTest
{
	public static function test():Void
	{
		testPatch();
        testPath();

		trace('JSONPatchTest: Done.');
	}

	public static function testPatch():Void
	{
        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "add", path: "/a/foo", value: 1 },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 2, "foo": 1, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "remove", path: "/a/b" },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "replace", path: "/a/b", value: 1 },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 1, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "move", from: "/a/b", path: "/a/c" },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "c": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "copy", from: "/a/b", path: "/a/c" },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 2, "c": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "test", path: "/a/b", value: 2 },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        //
        // From spec
        //

        // A.2.  Adding an Array Element
        var data = { "foo": [ "bar", "baz" ] };
        var patch = [ { "op": "add", "path": "/foo/1", "value": "qux" } ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "foo": [ "bar", "qux", "baz" ] });

        // A.12.  Adding to a Non-existent Target
        var data = { "foo": "bar" };
        var patch = [ { "op": "add", "path": "/baz/bat", "value": "qux" } ];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(data, patch);
            trace(result);
        }, 'add to a non-existent target');

        // A.15. Comparing Strings and Numbers
        var doc = { "/": 9, "~1": 10 };
        var patch = [ { "op": "test", "path": "/~01", "value": "10" } ];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(doc, patch);
            trace(result);
        }, 'test failed, values (10 =/= 10) not equivalent');

        // A.16. Adding an Array Value
        var doc = { "foo": ["bar"] };
        var patch = [{ "op": "add", "path": "/foo/-", "value": ["abc", "def"] }];
        var result = JSONPatch.applyPatches(doc, patch);
        var expected1:Array<Dynamic> = ["bar", ["abc", "def"]];
        var expected = { "foo": expected1 };
        Test.assertEquals(result, expected);

        // 
        // From test suite
        //

        // toplevel array
        var data = [];
        var patch = [{ op: "add", path: "/0", value: "foo" }];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, ["foo"]);

        // Out of bounds (upper)
        var data = {"bar": [1, 2]};
        var patch = [{ op: "add", path: "/bar/8", value: "foo" }];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(data, patch);
            trace(result);
        }, 'array index out of bounds');

        // Out of bounds (lower)
        var data = {"bar": [1, 2]};
        var patch = [{ op: "add", path: "/bar/-1", value: "foo" }];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(data, patch);
            trace(result);
        }, 'array index out of bounds');

        // replace object document with array document
        var data = {};
        var patch = [{ op: "replace", path: "", value: [] }];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, []);

        // test remove on array
        var doc = [1, 2, 3, 4];
        var patch = [{"op": "remove", "path": "/0"}];
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, [2, 3, 4]);
        
        // replacing the root of the document is possible with add
        var doc = {"foo": "bar"};
        var patch = [{"op": "add", "path": "", "value": {"baz": "qux"}}];
        var expected = {"baz":"qux"};
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, expected);

        // Multiple tests
        var doc = { "foo": ["bar", "baz"], "": 0, "a/b": 1, "c%d": 2, "e^f": 3, "g|h": 4, "i\\j": 5, "k\"l": 6, " ": 7, "m~n": 8 };
        var patch:Array<JSONData> = [
            {"op": "test", "path": "/foo", "value": ["bar", "baz"]},
            {"op": "test", "path": "/foo/0", "value": "bar"},
            {"op": "test", "path": "/", "value": 0},
            {"op": "test", "path": "/a~1b", "value": 1},
            {"op": "test", "path": "/c%d", "value": 2},
            {"op": "test", "path": "/e^f", "value": 3},
            {"op": "test", "path": "/g|h", "value": 4},
            {"op": "test", "path":  "/i\\j", "value": 5},
            {"op": "test", "path": "/k\"l", "value": 6},
            {"op": "test", "path": "/ ", "value": 7},
            {"op": "test", "path": "/m~0n", "value": 8}
        ];
        var expected = { "": 0, " ": 7, "a/b": 1, "c%d": 2, "e^f": 3, "foo": [ "bar", "baz" ], "g|h": 4, "i\\j": 5, "k\"l": 6, "m~n": 8 };
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, expected);

        // null value should still be valid obj property replace other value
        var doc = { "foo": "bar" };
        var patch = [{"op": "replace", "path": "/foo", "value": null}];
        var expected = { "foo": null };
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, expected);

        // Object operation on array target
        var doc = ["foo", "sil"];
        var patch = [{"op": "add", "path": "/bar", "value": 42}];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(doc, patch);
            trace(result);
        }, 'could not parse array index bar');

        // test against implementation-specific numeric parsing
        var doc = {"1e0": "foo"};
        var patch = [{"op": "test", "path": "/1e0", "value": "foo"}];
        var expected = {"1e0": "foo"};
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, expected);

        // test with bad array number that has leading zeros
        var doc = ["foo", "bar"];
        var patch = [{"op": "test", "path": "/00", "value": "foo"}];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(doc, patch);
            trace(result);
        }, 'could not parse array index 00');

        var doc = ["foo", "bar"];
        var patch = [{"op": "test", "path": "/01", "value": "bar"}];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(doc, patch);
            trace(result);
        }, 'could not parse array index 01');

        var doc = {"00": "foo", "01": "bar"};
        var patch = [{"op": "test", "path": "/01", "value": "bar"}];
        var result = JSONPatch.applyPatches(doc, patch);
        Test.assertEquals(result, {"00": "foo", "01": "bar"});
    }

    public static function testPath():Void {
        // Test custom behavior: uses of JSONPath

        var data = { "a": { "b": 2, "f": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "replace", path: "$.a.b", value: 3 },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 3, "f": "g" }, "cd": { "e": [3, 4, 5] } });

        var data = { "a": { "b": 2, "e": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "replace", path: "$..e", value: 3 },
        ];
        var result = JSONPatch.applyPatches(data, patch);
        Test.assertEquals(result, { "a": { "b": 2, "e": 3 }, "cd": { "e": 3 } });

        var data = { "a": { "b": 2, "e": "g" }, "cd": { "e": [3, 4, 5] } };
        var patch = [
            { op: "test", path: "$..e", value: "g" },
        ];
        Test.assertError(() -> {
            var result = JSONPatch.applyPatches(data, patch);
            trace(result);
        }, 'test failed, values ([3,4,5] =/= g) not equivalent');
    }
}