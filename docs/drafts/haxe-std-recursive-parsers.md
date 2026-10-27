Draft issue for HaxeFoundation/haxe (not posted)

Title: haxe.Unserializer, haxe.Serializer and haxe.Json overflow the native stack on deeply nested input

Labels: std

Found while fuzzing libhxcpp's parsers (openfl/libhxcpp#257).

`haxe.Unserializer.run`, `haxe.format.JsonParser` and the matching printers recurse once per level of nesting, so untrusted input nested a few thousand levels deep ends the program with a stack overflow instead of an exception. On the C++ target with a 1 MB main thread stack (the Windows default), 2000 nested arrays are enough:

```haxe
class Main {
	static function main() {
		var text = [for (i in 0...2000) "a"].join("") + [for (i in 0...2000) "h"].join("");
		try {
			haxe.Unserializer.run(text);
		} catch (e:Dynamic) {
			trace("rejected");
		}
	}
}
```

The same holds for `haxe.Json.parse` with 2000 nested `[`, and for printing a value that deep. Other targets reach their own limit at other depths; a JavaScript `RangeError` can at least be caught.

Possible fixes, from least to most work:

- a nesting limit in Unserializer and JsonParser, throwing a normal error past it (for example 512 levels, adjustable through a static field), which is what most JSON libraries do for untrusted input;
- or an explicit stack in place of recursion in the parsers.

Until then, code that reads untrusted serialized data or JSON has to bound the nesting itself. The libhxcpp fuzz targets skip input nested more than 200 levels for this reason (test/fuzz/Fuzz.hx, MAX_NESTING).

---

Two smaller std findings from the same fuzzing, each worth its own issue:

1. `haxe.Json.stringify` writes U+0000 into a string as it is, and on the C++ (and HashLink) targets `JsonParser` takes a NUL code unit for the end of the text (`StringTools.isEof`), so `Json.parse(Json.stringify(v))` throws "Unclosed string" for a value holding one. The printer escapes `\n`, `\r`, `\t`, `\b` and `\f` but no other control character; JSON requires all of U+0000 to U+001F to be escaped (RFC 8259, section 7). Such a string comes, for example, from `Json.parse('{"\u@-.":1}')`, where `Std.parseInt("0x@-.")` is unspecified and gives 0 on C++ rather than an error.

2. On C++, `Date.fromTime(t).getTime()` is not `t` when `t` has a fraction of a millisecond (`777777777777.0001` comes back as `777777777777.0002`), because `cpp/_std/Date.hx` keeps the time in seconds. So `Serializer` then `Unserializer` changes such a date on every round.
