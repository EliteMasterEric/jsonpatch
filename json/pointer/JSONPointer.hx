package json.pointer;

class JSONPointer {
	static final SLASH:Int = 0x2F; // /
    static final TILDE:Int = 0x7E; // ~

    static final EOL:Int = -1;

    /**
     * Convert a JSONPointer to normalized JSONPath string.
     */
    public static function toJSONPath(path:String):String {
        if (path == '') return '$';

        var readPos = 0;

        function peek(index:Int = 0):Int {
            if (readPos >= path.length) return -1;
            return StringTools.fastCodeAt(path, readPos + index);
        }

        function pop():Int {
            if (readPos >= path.length) return -1;
            return StringTools.fastCodeAt(path, readPos++);
        }

        function popStr():String {
            return String.fromCharCode(pop());
        }

        function eol():Bool {
            return peek() == EOL;
        }
        
        function slash():Bool {
            return peek() == SLASH;
        }

        function tilde():Bool {
            return peek() == TILDE;
        }

        function popReferenceToken():String {
            var result = "";
            while (!eol() && !slash()) {
                if (tilde()) {
                    pop();
                    var escaped = popStr();
                    switch (escaped) {
                        case "0":
                            result += "~";
                        case "1":
                            result += "/";
                        default:
                            throw 'Expected 0 or 1 at position ${readPos-1}, got ${escaped}';
                    }
                } else {
                    result += popStr();
                }
            }
            return result;
        }

        function toInt(input:String):Null<Int> {
            // TODO: Are exponents really bad numbers?
            var result = Std.parseInt(input);
            if (result != null) {
                if (input.indexOf('e') != -1 || input.indexOf('E') != -1) {
                    // 1e0 is not valid
                    // throw 'bad number: ' + input;
                    return null;
                } else if (StringTools.startsWith(input, '0') && result != 0) {
                    // 04 is not valid
                    // throw 'bad number: ' + input;
                    return null;
                } else if (result == 0 && input.length > 1) {
                    // 00 is not valid
                    // throw 'bad number: ' + input;
                    return null;
                }

                return result;
            } else {
                return null;
            }
        }

        var result = "$";

        while (!eol()) {
            var char = peek();
            var charStr = popStr();
            switch (char) {
                case SLASH:
                    var token = popReferenceToken();
                    if (token.length > 0) {
                        if (toInt(token) != null) {
                            result += "[" + token + "]";
                        } else {
                            result += "['" + token + "']";
                        }
                    } else {
                        result += "['']";
                    }
                default:
                    throw 'Expected "/" at position ${readPos-1}, got ${charStr}';
            }                
        }

        return result;
    }
}