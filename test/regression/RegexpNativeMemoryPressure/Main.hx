@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static inline var PATTERN = "(?:abcdefghij){1000}";
	// Not ASCII, so a match compiles each expression again for 16-bit units
	static inline var WIDE = "unrelated é";

	static var kept:Array<EReg>;
	static var usable:Bool;

	static function large():Float {
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
	}

	static function collect():Float {
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		return large();
	}

	static function run(f:Void->Void) {
		untyped __cpp__("runJoined({0})", f);
	}

	static function keep() {
		kept = [for (i in 0...128) new EReg(PATTERN, "")];
		for (r in kept)
			r.match("unrelated");
	}

	static function widen() {
		for (r in kept)
			r.match(WIDE);
	}

	static function verify() {
		var text = [for (i in 0...1000) "abcdefghij"].join("");
		usable = kept[0].match("<" + text + ">") && kept[1].match("é" + text) && !kept[2].match(WIDE);
	}

	static function release() {
		kept = null;
	}

	static function abandon() {
		for (i in 0...128)
			new EReg(PATTERN, "").match("unrelated");
	}

	static function main() {
		var baseline = collect();
		run(keep);
		var growth = collect() - baseline;
		Sys.println("compiled expressions contribute to GC pressure: " + (growth > 1024 * 1024));
		run(widen);
		Sys.println("second width compilation contributes to GC pressure: " + (collect() - baseline > growth + 1024 * 1024));
		run(verify);
		Sys.println("retained expressions remain usable: " + usable);
		run(release);
		Sys.println("finalization removes reported native pressure: " + (collect() - baseline < 1024 * 1024));
		run(abandon);
		Sys.println("abandoned expressions are released: " + (collect() - baseline < 1024 * 1024));
		#if audit_counts
		Sys.stderr().writeString("growth: " + growth + "\n");
		#end
	}
}
