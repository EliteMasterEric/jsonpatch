# JSONPatch

A library for parsing and evaluating [JSONPatch](https://jsonpatch.com/) files on JSON data objects.

It deviates from the spec to add support for additional features, but seeks to otherwise be fully compatible with JSONPatch data that is compliant with [RFC6902](https://datatracker.ietf.org/doc/rfc6902/).

Additional features include:

- The ability to test that a key exists by omitting `value` from the `test` operation.
- The ability to invert a test by providing `"inverse": true` in the `test` operation.
- The ability to provide a batch of JSONPatches to evaluate one at a time, gracefully skipping the patches containing a failed operation.
- The ability to use JSONPath for the path argument, instead of only supporting JSONPointer values.

## Example

```haxe
import json.patch.JSONPatch;

var patch = [
    {"op": "add", "path": "/a/d", "value": "e"}
];
var data = {"a": {"b": "c"}}

// {"a": {"b": "c", "d": "e"}}
trace(JSONPatch.applyPatches(patch, data));

// JSONPath is also supported.
var patch = [
    {"op": "replace", "path": "$..c", "value": 3}
];
var data = {"a": {"c": 11}, "b": {"c": 12}};

// {"a": {"c": 3 }, "b": { "c": 3 }}}
trace(JSONPatch.applyPatches(patch, data));
```

## Licensing

JSONPatch is made available under an open source MIT License. You can read more at [LICENSE](LICENSE.md).
