// A failed match left the regex's UTF-16 validation cache holding the whole
// subject, and for one with a lone surrogate its sanitized copy too, until
// the regex was dropped. The subject is made and matched on a native thread
// that has gone by the time the heap is measured, so only the regex holds it.
@:cppFileCode('
#include <hx/Native.h>
#include <thread>
static String failedMatchSubject(bool invalid) {
	const int count = 4 * 1024 * 1024;
	char16_t *data = String::allocChar16Ptr(count);
	for (int i=0; i<count; ++i) data[i] = 0x100;
	if (invalid) data[count-1] = 0xd800;
	return String(data, count);
}
static void failedMatchWorker(Dynamic action) {
	hx::AutoGCFreeZone zone;
	std::thread worker([&]() {
		hx::NativeAttach attached;
		action();
	});
	worker.join();
}
')
class Main {
	static var regex:EReg;
	static var invalid:Bool;

	static function populate() {
		regex = new EReg("Z", "");
		var subject:String = untyped __cpp__("failedMatchSubject({0})", invalid);
		if (regex.match(subject)) throw "unexpected match";
	}

	static function collect():Float {
		for (_ in 0...3) cpp.vm.Gc.run(true);
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
	}

	static function main() {
		#if !hxcpp_smart_strings
		Sys.println("failed UTF16 subject cache is bounded: true");
		Sys.println("failed sanitized subject cache is bounded: true");
		Sys.println("dropping the regex releases both buffers: true");
		#else
		var baseline = collect();
		for (sanitize in [false, true]) {
			invalid = sanitize;
			var action:Dynamic = populate;
			untyped __cpp__("failedMatchWorker({0})", action);
			var retained = collect() - baseline;
			Sys.stderr().writeString((sanitize ? "sanitized" : "valid") + " retained bytes: " + retained + "\n");
			Sys.println((sanitize ? "failed sanitized subject cache is bounded: " : "failed UTF16 subject cache is bounded: ") + (retained < 1024 * 1024));
		}
		regex = null;
		Sys.println("dropping the regex releases both buffers: " + (collect() - baseline < 1024 * 1024));
		#end
		// A small subject keeps its cache, and matches after a failure still work
		var small = new EReg("b", "");
		var text = String.fromCharCode(0x100) + "a" + String.fromCharCode(0x100) + "b" + String.fromCharCode(0xd800);
		var found = !small.matchSub(text, 0, 2) && small.matchSub(text, 0) && small.matchedPos().pos == 3;
		Sys.println("matching after a failure finds the next match: " + found);
	}
}
