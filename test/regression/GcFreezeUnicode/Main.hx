class Main {
	static function freeze<T>(value:T):T
		return untyped __cpp__("_hx_gc_freeze({0})", value);

	static function main() {
		// Built at run time, so the strings are GC allocations rather than constants
		var text = ["雪", "73"].join(":");
		var ascii = ["ascii", "73"].join(":");
		var keys = new haxe.ds.StringMap<Int>();
		keys.set(text, 73);
		var original = {text: text, items: [text], ascii: ascii};
		var allocated:Bool = untyped __cpp__("!__hxcpp_is_const_string({0})", text);
		var frozen = freeze(original);
		var field:String = frozen.text;
		var element:String = frozen.items[0];
		var shared:Bool = untyped __cpp__("({0}.raw_ptr()=={1}.raw_ptr())", field, element);
		Sys.println("source Unicode string is runtime allocated: " + allocated);
		Sys.println("frozen Unicode field preserves text: " + (frozen.text == text));
		Sys.println("frozen Unicode array element preserves text: " + (frozen.items[0] == text));
		Sys.println("frozen Unicode strings stay shared: " + shared);
		Sys.println("frozen Unicode character decoding remains correct: " + (frozen.text.charCodeAt(0) == 0x96ea && frozen.text.length == 4));
		Sys.println("frozen Unicode string hashes as its source: " + (keys.get(frozen.text) == 73));
		Sys.println("frozen ASCII string control remains correct: " + (frozen.ascii == ascii));
		cpp.vm.Gc.compact();
		Sys.println("frozen Unicode text survives collection: " + (frozen.text == text && frozen.items[0] == text));
	}
}
