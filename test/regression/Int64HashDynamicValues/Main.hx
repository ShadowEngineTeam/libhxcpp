// An Int64-keyed map set through its Dynamic setter, as generic code sets
// it, keeps Int64 value storage for Int64 values instead of boxing each one.
// HashRoot::store is read from the runtime's own header, which is why this is
// a program of its own: it adds the runtime's src directory to its includes.
@:buildXml('<files id="haxe"><compilerflag value="-I${HXCPP}/src"/></files>')
@:cppFileCode('#include <hx/Hash.h>')
class Main {
	var h:Dynamic;

	function new() {}

	function set(key:haxe.Int64, value:Dynamic):Void {
		untyped __global__.__int64_hash_set(__cpp__("HX_MAP_THIS"), key, value);
	}

	function get(key:haxe.Int64):Dynamic {
		return untyped __global__.__int64_hash_get(h, key);
	}

	function getInt64(key:haxe.Int64):haxe.Int64 {
		return untyped __global__.__int64_hash_get_int64(h, key);
	}

	function storeIs(store:String):Bool {
		var s:Int = untyped __cpp__("(int)static_cast<hx::HashRoot*>({0}.mPtr)->store", h);
		return switch (store) {
			case "Int64": s == untyped __cpp__("(int)hx::hashInt64");
			case "Int": s == untyped __cpp__("(int)hx::hashInt");
			case "object": s == untyped __cpp__("(int)hx::hashObject");
			default: false;
		}
	}

	static function main() {
		var first = haxe.Int64.make(1, 7);
		var second = haxe.Int64.make(2, 9);
		var map = new Main();
		map.set(1, first);
		Sys.println("first Int64 value gets Int64 storage: " + map.storeIs("Int64"));
		map.set(2, second);
		Sys.println("second Int64 value keeps Int64 storage: " + map.storeIs("Int64"));
		Sys.println("Int64 values read back: " + (map.getInt64(1) == first && map.getInt64(2) == second));

		var widened = new Main();
		widened.set(1, 5);
		Sys.println("Int value gets Int storage: " + widened.storeIs("Int"));
		widened.set(2, second);
		Sys.println("Int64 after an Int widens to Int64 storage: " + widened.storeIs("Int64"));
		widened.set(3, 6);
		Sys.println("Int after the Int64 keeps Int64 storage: " + widened.storeIs("Int64"));
		Sys.println("widened values read back: " + (widened.getInt64(1) == 5 && widened.getInt64(2) == second && widened.getInt64(3) == 6));

		var mixed = new Main();
		mixed.set(1, first);
		mixed.set(2, "text");
		Sys.println("String after an Int64 gets object storage: " + mixed.storeIs("object"));
		mixed.set(3, second);
		Sys.println("Int64 after the String keeps object storage: " + mixed.storeIs("object"));
		var boxed:Dynamic = mixed.get(3);
		Sys.println("mixed values read back: " + (mixed.getInt64(1) == first && mixed.get(2) == "text" && (boxed : haxe.Int64) == second));
		Sys.println("missing key reads null: " + (mixed.get(4) == null));
	}
}
