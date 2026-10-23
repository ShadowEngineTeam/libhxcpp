class Main {
	static function main() {
		var map = new haxe.ds.ObjectMap<{}, Dynamic>();
		var first = {};
		var second = {};
		var exact = haxe.Int64.make(0x200000, 1);
		map.set(first, exact);
		var before:haxe.Int64 = cast map.get(first);
		map.set(second, 1.5);
		var after:haxe.Int64 = cast map.get(first);
		Sys.println("initial Int64 preserved: " + (before == exact));
		Sys.println("Float insertion preserves prior Int64: " + (after == exact));
		Sys.println("Float value preserved: " + (map.get(second) == 1.5));
		var reverse = new haxe.ds.ObjectMap<{}, Dynamic>();
		reverse.set(second, 1.5);
		reverse.set(first, exact);
		var reverseValue:haxe.Int64 = cast reverse.get(first);
		Sys.println("reverse insertion order preserves Int64: " + (reverseValue == exact));
		var strings = new haxe.ds.StringMap<Dynamic>();
		strings.set("first", exact);
		strings.set("second", 1.5);
		var stringValue:haxe.Int64 = cast strings.get("first");
		Sys.println("StringMap control preserves Int64: " + (stringValue == exact));
		var integers = new haxe.ds.IntMap<Dynamic>();
		integers.set(1, exact);
		integers.set(2, 1.5);
		var integerValue:haxe.Int64 = cast integers.get(1);
		Sys.println("IntMap control preserves Int64: " + (integerValue == exact));
	}
}
