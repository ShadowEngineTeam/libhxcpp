@:cppFileCode('
static size_t sBefore = 0;
static void keepFinalizer(void *) {}
')
class Main {
	static var held:Array<Int>;

	static function setup() {
		held = [for (i in 0...64) i];
		untyped __cpp__("__hxcpp_add_alloc_finalizer(::Main_obj::held.mPtr, keepFinalizer, true); sBefore = (size_t)::Main_obj::held.mPtr");
	}

	static function churn() {
		var junk = [for (i in 0...20000) [i]];
		return junk.length;
	}

	static function main() {
		setup();
		for (i in 0...5) {
			churn();
			cpp.vm.Gc.run(true);
		}
		var same:Bool = untyped __cpp__("sBefore == (size_t)::Main_obj::held.mPtr");
		Sys.println(same ? "pinned" : "moved");
		Sys.println(held.length == 64 && held[63] == 63 ? "intact" : "corrupt");
	}
}
