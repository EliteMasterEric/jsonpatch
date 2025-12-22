package json.patch;

import haxe.ds.Either;
import json.pointer.JSONPointer;
import json.JSONData;
import json.util.TypeUtil;
import json.path.JSONPath;

using StringTools;

typedef JSONPatchOperation = JSONData;

class JSONPatch {

    /**
     * For the given JSON data, apply all the provided JSONPatches.
     * @param data A JSON data object. You can pass `Dynamic` or `Array<Dynamic>` here.
     * @param patchBatch Either a JSON Patch (as an array of operations) or an array of JSON Patches (i.e. an array of arrays of operations)
     *   If multiple patches are provided, each will apply to the data in order.
     *   In the event of a failed patch, the data will not be modified and the next patch will be evaluated.
     * @return The resulting JSON data.
     */
    public static function applyPatches(data:JSONData, patchBatch:Array<Dynamic>):JSONData {
        if (patchBatch == null || patchBatch.length == 0) return data;

        // true = array of arrays, false = array of objects, null = not yet determined
        var isBatch = false;
        var isSinglePatch:Bool = false;
        
        // Distinguish between a single patch and an array of patches.
        for (patch in patchBatch) {
            if (Std.isOfType(patch, Array)) {
                // patch is an Array of objects.
                isBatch = true;
                if (isSinglePatch) throw "Cannot mix individual operations with patches!";
            } else {
                // patch is an Object
                isSinglePatch = true;
                if (isBatch) throw "Cannot mix individual operations with patches!";
            }
        }

        if (isSinglePatch) {
            var patch:Array<JSONPatchOperation> = patchBatch;
            try {
                return JSONPatch.applyPatch(data, patch);
            } catch (e) {
                // The only patch in the batch failed, throw the error!
                throw e;
            }
        } else if (isBatch) {
            var result:JSONData = data.copy();
            var successes:Int = 0;
            var failures:Int = 0;
            for (patch in patchBatch) {
                try {
                    result = JSONPatch.applyPatch(result, patch);
                    successes += 1;
                } catch (e) {
                    // The patch failed, skip it and continue.
                    // TODO: Improve error handling for each patch
                    trace('Failed to apply patch ${successes+1}/${patchBatch.length}: ' + e);
                    failures += 1;
                }
            }
            // trace('${successes}/${patchBatch.length} patches applied successfully.');
            return result;
        } else {
            throw "Neither single patch nor batch of patches provided? Huh?";
        }
    }

    /**
     * For the given JSON data, apply all the provided JSONPatch operations.
     * @param data A JSON data object. You can pass `Dynamic` or `Array<Dynamic>` here.
     * @param patch An array of JSONPatch operations to perform.
     * @throws error If any of the operations fail or any of the `tests` return `false`.
     *   Your application should catch these errors, log them for users to fix,
     *   and return the unmodified original data.
     * @see https://datatracker.ietf.org/doc/rfc6902/
     * @return The resulting JSON data.
     */
    public static function applyPatch(data:JSONData, patch:Array<JSONPatchOperation>):JSONData {
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
    public static function applyOperation(data:JSONData, operation:JSONPatchOperation):JSONData {
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
                result = applyOperation_test(result, operation.get('path'), operation.get('value', NoValue), operation.get('inverse', false));
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

    static function applyOperation_test(data:JSONData, path:String, expected:Dynamic, inverse:Bool):JSONData {
        if (path == null) throw 'path is required';
        
        // If the value is excluded, we check if the target value exists and has ANY value.
        var testExists = expected == NoValue;

        // Query the target location
        // The value at the target location must exist and must be equal to the provided value
        // Otherwise, an error is thrown

        var targetPaths = parsePaths(path, data);

        for (targetPath in targetPaths) {
            try {

                if (!data.existsByPath(targetPath)) {
                    if (inverse && testExists) {
                        // Inverse existence test passed
                        continue;
                    } else {
                        throw 'test failed, target not found';
                    }
                }

                // If we are only testing for existence, then we can skip checking the value
                if (testExists && !inverse) {
                    // Continue to the next target path
                    continue;
                } else if (testExists && inverse) {
                    throw 'test failed, target exists';
                }
                
                var actual = data.getByPath(targetPath);
                
                if (!thx.Dynamics.equals(actual, expected)) {
                    if (inverse) {   
                        // Continue to the next target path
                        continue;
                    } else {
                        throw 'test failed, values (${actual} =/= ${expected}) not equivalent';
                    }
                } else {
                    if (inverse) {
                        throw 'test failed, values (${actual} == ${expected}) are equivalent';
                    } else {
                        // Continue to the next target path
                        continue;
                    }
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