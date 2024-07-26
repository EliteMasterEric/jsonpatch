package json.pointer;

import json.pointer.JSONPointer;
import json.path.JSONPath;
import json.path.JSONPath.Element;
import json.JSONData;

class JSONPointerTest
{
	public static function test():Void
	{
		testPointer();

		trace('JSONPathTest: Done.');
	}

	public static function testPointer():Void
	{
		var result = JSONPointer.toJSONPath('');
		Test.assertEquals(result, '$');

		var result = JSONPointer.toJSONPath('/foo');
		Test.assertEquals(result, "$['foo']");

		var result = JSONPointer.toJSONPath('/foo/0');
		Test.assertEquals(result, "$['foo'][0]");

		var result = JSONPointer.toJSONPath('/foo/0/bar');
		Test.assertEquals(result, "$['foo'][0]['bar']");

		var result = JSONPointer.toJSONPath('/');
		Test.assertEquals(result, "$['']");

		var result = JSONPointer.toJSONPath('/a~1b');
		Test.assertEquals(result, "$['a/b']");

		var result = JSONPointer.toJSONPath('/c%d');
		Test.assertEquals(result, "$['c%d']");

		var result = JSONPointer.toJSONPath('/e^f');
		Test.assertEquals(result, "$['e^f']");

		var result = JSONPointer.toJSONPath('/g|h');
		Test.assertEquals(result, "$['g|h']");

		var result = JSONPointer.toJSONPath('/i\\j');
		Test.assertEquals(result, "$['i\\j']");

		var result = JSONPointer.toJSONPath('/k"l');
		Test.assertEquals(result, "$['k\"l']");

		var result = JSONPointer.toJSONPath('/ ');
		Test.assertEquals(result, "$[' ']");

		var result = JSONPointer.toJSONPath('/m~0n');
		Test.assertEquals(result, "$['m~n']");
	}
}
