package json.patch;

import json.pointer.JSONPointer;
import json.JSONData;
import json.util.TypeUtil;
import json.path.JSONPath;

using StringTools;

class JSONPatch {

    /**
     * For the given JSON data, apply all the provided JSONPatch operations.
     * @param data A JSON data object. You can pass `Dynamic` or `Array<Dynamic>` here.
     * @param patch An array of JSONPatch operations to perform.
     * @see https://datatracker.ietf.org/doc/rfc6902/
     * @return The resulting JSON data.
     */
    public static function applyPatches(data:JSONData, patch:Array<JSONData>):JSONData {
        if (data == null || patch == null) return null;
        if (patch.length == 0) return data;
        
        var result:JSONData = data.copy();
        
        var firstOperation = true;

        for (operation in patch) {
            result = JSONPatch.applyOperation(result, operation);
        }

        return result;
    }

    /**
     * For the given JSON data, apply a single JSONPatch operation.
     * @param data A JSON data object. You can pass `Dynamic` or `Array<Dynamic>` here.
     * @param patch A JSONPatch operation to perform.
     * @see https://datatracker.ietf.org/doc/rfc6902/
     * @return The resulting JSON data.
     */
    public static function applyOperation(data:JSONData, operation:JSONData):JSONData {
        if (operation == null) return data;

        var result = data.copy();

        switch (operation.get('op')) {
            case "add":
                result = applyOperation_add(result, operation.get('path'), operation.get('value', NoValue));
            case "remove":
                result = applyOperation_remove(result, operation.get('path'));
            case "replace":
                result = applyOperation_replace(result, operation.get('path'), operation.get('value', NoValue));
            case "move":
                result = applyOperation_move(result, operation.get('from'), operation.get('path'));
            case "copy":
                result = applyOperation_copy(result, operation.get('from'), operation.get('path'));
            case "test":
                result = applyOperation_test(result, operation.get('path'), operation.get('value', NoValue));
            default:
                throw 'Unsupported operation "${operation.get('op')}", expected one of "test", "add", "replace", "remove", "move", "copy"';
        }

        return result;
    }

    static function applyOperation_add(data:JSONData, path:String, value:Dynamic):JSONData {
        if (path == null) throw 'path is required';
        if (value == NoValue) throw 'value is required';

        // If target is an array index, new value is inserted at that index
        // If target specifies an object member that does not exist, a new member is added to tha tojbect
        // If target specifies an object member that does exist, that member's value is replaced

        var targetPaths = parsePaths(path, data);

        for (targetPath in targetPaths) {
            try {
                data.insertByPath(targetPath, value, true);
            } catch (e) {
                if ('$e'.contains('does not exist')) {
                    throw 'add to a non-existent target';
                } else if ('$e'.contains('is out of bounds')) {
                    throw 'array index out of bounds';   
                } else if ('$e'.contains('insert(): bad array index: ')) {
                    var badIndex = '$e'.replace('insert(): bad array index: ', '');
                    throw 'could not parse array index ${badIndex}';
                } else {
                    throw e;
                }
            }   
        }

        return data;
    }

    static function applyOperation_remove(data:JSONData, path:String):JSONData {
        if (path == null) throw 'path is required';
        // trace('Remove: Path "${path}"');

        // Remove the value at the target location
        // If target is an array index, the value is removed and other elements are shifted

        var targetPaths = parsePaths(path, data);

        for (targetPath in targetPaths) {
            if (!data.existsByPath(targetPath)) {
                throw 'remove target ${targetPath} does not exist';
            }
            data.removeByPath(targetPath);
        }

        return data;
    }

    static function applyOperation_replace(data:JSONData, path:String, value:Dynamic):JSONData {
        if (path == null) throw 'path is required';
        if (value == NoValue) throw 'value is required';

        // Replace the value at the target location
        // If target is an array index, the value is replaced
        // If target specifies an object member that does exist, that member's value is replaced

        var targetPaths = parsePaths(path, data);

        for (targetPath in targetPaths) {
            data.setByPath(targetPath, value);
        }

        return data;
    }

    static function applyOperation_move(data:JSONData, from:String, path:String):JSONData {
        if (path == null) throw 'path is required';
        if (from == null) throw 'from is required';

        // Get the value at the from location
        // Then, remove the value at the from location
        // Then, add the value at the path location

        var targetFromPaths = parsePaths(from, data);
        var targetPaths = parsePaths(path, data);

        for (targetFromPath in targetFromPaths) {
            if (!data.existsByPath(targetFromPath)) {
                throw 'no element at from path ${targetFromPath}';
            }

            var value = data.getByPath(targetFromPath);
            data.removeByPath(targetFromPath);
            for (targetPath in targetPaths) {
                data.setByPath(targetPath, value);
            }
        }

        return data;
    }

    static function applyOperation_copy(data:JSONData, from:String, path:String):JSONData {
        if (path == null) throw 'path is required';
        if (from == null) throw 'from is required';

        // Get the value at the from location
        // Then, add the value at the path location

        var targetFromPaths = parsePaths(from, data);
        var targetPaths = parsePaths(path, data);

        for (targetFromPath in targetFromPaths) {
            if (!data.existsByPath(targetFromPath)) {
                throw 'no element at from path ${targetFromPath}';
            }

            var value = data.getByPath(targetFromPath);
            for (targetPath in targetPaths) {
                data.setByPath(targetPath, value);
            }
        }

        return data;
    }

    static function applyOperation_test(data:JSONData, path:String, expected:Dynamic):JSONData {
        if (path == null) throw 'path is required';
        if (expected == NoValue) throw 'value is required';

        // Query the target location
        // The value at the target location must exist and must be equal to the provided value
        // Otherwise, an error is thrown

        var targetPaths = parsePaths(path, data);

        for (targetPath in targetPaths) {
            try {

                if (!data.existsByPath(targetPath)) {
                    throw 'test failed, target not found';
                }
                
                var actual = data.getByPath(targetPath);
                
                if (!thx.Dynamics.equals(actual, expected)) {
                    throw 'test failed, values (${actual} =/= ${expected}) not equivalent';
                }
            } catch (e) {
                if ('$e'.startsWith('test failed')) {
                    throw e;
                } else if ('$e'.contains('exists(): bad array index: ')) {
                    var badIndex = '$e'.replace('exists(): bad array index: ', '');
                    throw 'could not parse array index ${badIndex}';
                } else {
                    throw e;
                }
            }   
        }

        return data;
    }

    static function parsePaths(path:String, data:JSONData):Array<String> {
        // Parse a JSONPath string
        if (path.startsWith('$')) return JSONPath.queryPaths(path, data);

        // Parse a JSONPointer string.
        return [JSONPointer.toJSONPath(path)];
    }
}

enum NoValue {
    NoValue;
}