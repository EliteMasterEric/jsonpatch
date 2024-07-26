# JSONPatch

A library for parsing and evaluating [JSONPatch](https://jsonpatch.com/) files on JSON data objects.

It deviates from the spec in that it supports both [JSONPointer](https://datatracker.ietf.org/doc/rfc6901/) and [JSONPath](https://datatracker.ietf.org/doc/rfc9535/) for the path argument.

The implementation seeks to otherwise be compliant with [RFC6902](https://datatracker.ietf.org/doc/rfc6902/).

## Example

```haxe
import json.patch.JSONPatch;

var patch = [
    {"op": "add", "path": "/a/d", "value": "e"}
];
var data = {"a": {"b": "c"}}

// {"a": {"b": "c", "d": "e"}}
trace(JSONPatch.applyPatch(patch, data));

// JSONPath is also supported.
var patch = [
    {"op": "replace", "path": "$..c", "value": 3}
];
var data = {"a": {"c": 11}, "b": {"c": 12}};

// {"a": {"c": 3 }, "b": { "c": 3 }}}
trace(JSONPatch.applyPatch(patch, data));
```

## Licensing

JSONPatch is made available under an open source MIT License. You can read more at [LICENSE](LICENSE.md).
