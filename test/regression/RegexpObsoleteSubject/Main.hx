@:cppFileCode('
#include <hx/Native.h>
#include <thread>
static String auditWideSubject() {
	const int size = 4 * 1024 * 1024;
	char16_t *data = String::allocChar16Ptr(size);
	for (int i=0; i<size; ++i) data[i] = 0x100;
	return String(data, size);
}
static void auditRunWorker(Dynamic action) {
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
	static function populate() {
		regex = new EReg("Z", "");
		var subject:String = untyped __cpp__("auditWideSubject()");
		if (regex.match(subject)) throw "Unexpected match";
		if (regex.match("a")) throw "Unexpected match";
	}
	static function collect():Float {
		for (i in 0...3) cpp.vm.Gc.run(true);
		return cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_USAGE);
	}
	static function main() {
		#if !hxcpp_smart_strings
		Sys.println("obsolete subject released: true");
		#else
		var baseline = collect();
		var action:Dynamic = populate;
		untyped __cpp__("auditRunWorker({0})", action);
		var retained = collect() - baseline;
		Sys.println("obsolete subject released: " + (retained < 1024 * 1024));
		regex = null;
		collect();
		#end
	}
}
