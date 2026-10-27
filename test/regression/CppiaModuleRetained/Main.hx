import cpp.cppia.Host;
import cpp.cppia.Module;
import cpp.vm.Gc;

// __scriptable_cppia_retained() collects, then lists each released module
// still loaded with what of it is still live: here three Things and two
// closures the host holds, and not the Others that only its cleared static
// had. The module is loaded, held, used and dropped on joined native workers,
// so stale values on the main thread's stack do not decide what is live.
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
	std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
')
class Main {
	static var bytes:haxe.io.Bytes;
	static var held:Array<Dynamic>;
	static var works:Bool;

	static function loadHoldRelease() {
		var module = Module.fromData(bytes.getData());
		module.boot();
		module.run();
		var thing = module.resolveClass("Thing");
		held = [for (i in 0...3) Type.createInstance(thing, [i])];
		held.push(Reflect.field(held[0], "get"));
		held.push(Reflect.callMethod(null, Reflect.field(module.resolveClass("Script"), "adder"), [2]));
		untyped module.release();
	}

	static function useHeld() {
		var get:Void->Int = held[3];
		var add:Int->Int = held[4];
		works = get() == 0 && add(1) == 3;
	}

	static function drop() {
		held = null;
	}

	static function retained():Array<Dynamic> {
		return untyped __global__.__scriptable_cppia_retained();
	}

	static function describe(instances:Array<Dynamic>):String {
		return [for (i in instances) '${i.name} x${i.count}' + (i.bytes > 0 ? "" : " (no bytes)")].join(", ");
	}

	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			Host.enableJit(jit);
			untyped __cpp__("runJoined({0})", loadHoldRelease);

			var report = retained();
			Sys.println('jit $jit: the released module is listed while held: ${report.length == 1}');
			if (report.length == 1) {
				var instances = describe(report[0].instances);
				if (instances != "Thing x3")
					Sys.stderr().writeString('instances: $instances\n');
				Sys.println('jit $jit: its live instances are the three Things held: ${instances == "Thing x3"}');
				var closures:Int = report[0].closures.count;
				if (closures != 2)
					Sys.stderr().writeString('closures: $closures\n');
				Sys.println('jit $jit: its closures are the bound method and the closure held: ${closures == 2 && report[0].closures.bytes > 0}');
			}

			untyped __cpp__("runJoined({0})", useHeld);
			Sys.println('jit $jit: what is held still works: $works');

			untyped __cpp__("runJoined({0})", drop);
			Gc.run(true);
			Sys.println('jit $jit: once dropped it is freed and not listed: ${retained().length == 0}');
		}
	}
}
