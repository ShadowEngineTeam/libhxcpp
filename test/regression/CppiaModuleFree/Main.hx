import cpp.vm.Gc;

@:cppFileCode('
#if defined(__SANITIZE_ADDRESS__)
#define TEST_ASAN 1
#elif defined(__has_feature)
#if __has_feature(address_sanitizer)
#define TEST_ASAN 1
#endif
#endif
#if defined(_MSC_VER)
#define SCRUB_NOINLINE __declspec(noinline)
#if defined(TEST_ASAN)
#define SCRUB_PLAIN __declspec(no_sanitize_address)
#endif
#else
#define SCRUB_NOINLINE __attribute__((noinline))
#if defined(TEST_ASAN)
#define SCRUB_PLAIN __attribute__((no_sanitize_address))
#endif
#endif
#ifndef SCRUB_PLAIN
#define SCRUB_PLAIN
#endif
// Clears stale pointers that calls left on the stack, which the collector scans conservatively.
// Without AddressSanitizer, whose frame header the loop would not reach.
static SCRUB_NOINLINE SCRUB_PLAIN void scrubStack()
{
	volatile char buffer[256 * 1024];
	for (int i = 0; i < (int)sizeof(buffer); i++)
		buffer[i] = 0;
}
// AddressSanitizer keeps freed memory in quarantine, so the process grows anyway
#if defined(TEST_ASAN)
static double processMemory()
{
	return 0;
}
#elif defined(HX_WINDOWS)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <psapi.h>
static double processMemory()
{
	PROCESS_MEMORY_COUNTERS_EX counters;
	counters.cb = sizeof(counters);
	K32GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS *)&counters, sizeof(counters));
	return (double)counters.PrivateUsage;
}
#elif defined(__linux__)
#include <stdio.h>
#include <unistd.h>
static double processMemory()
{
	long pages = 0, resident = 0;
	FILE *file = fopen("/proc/self/statm", "r");
	if (file)
	{
		if (fscanf(file, "%ld %ld", &pages, &resident) != 2)
			resident = 0;
		fclose(file);
	}
	return (double)resident * sysconf(_SC_PAGESIZE);
}
#elif defined(__APPLE__)
#include <mach/mach.h>
static double processMemory()
{
	mach_task_basic_info_data_t info;
	mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
	if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &count) != KERN_SUCCESS)
		return 0;
	return (double)info.resident_size;
}
#else
#include <sys/resource.h>
static double processMemory()
{
	struct rusage usage;
	getrusage(RUSAGE_SELF, &usage);
	return (double)usage.ru_maxrss * 1024.0;
}
#endif
')
class Main {
	static var bytes:haxe.io.Bytes;
	static var keep:Dynamic;
	static var module:cpp.cppia.Module;
	static var duringCallback = -1;
	static var base = 0;

	static function live():Int
		return untyped __cpp__("__scriptable_cppia_live_modules()");

	static function memory():Float
		return untyped __cpp__("processMemory()");

	static function collect() {
		untyped __cpp__("scrubStack()");
		for (i in 0...3)
			Gc.run(true);
	}

	static function load():cpp.cppia.Module {
		var m = cpp.cppia.Module.fromData(bytes.getData());
		m.boot();
		m.run();
		return m;
	}

	static function release(m:cpp.cppia.Module) {
		untyped m.release();
	}

	static function scriptClass(name:String):Dynamic {
		return module.resolveClass(name);
	}

	static function call(name:String, args:Array<Dynamic>):Dynamic {
		var cls = scriptClass("Script");
		return Reflect.callMethod(cls, Reflect.field(cls, name), args);
	}

	// Module handling stays in functions that have returned before a check collects,
	// so no stale pointer in the checking frame keeps a module

	static function loadAndKeep(take:Void->Dynamic) {
		module = load();
		keep = take();
		release(module);
		module = null;
	}

	static function cycle() {
		var m = load();
		release(m);
	}

	// Through a closure, which the C++ compiler cannot inline into the caller's frame
	static function isolated<T>(f:Void->T):T
		return f();

	static function reloads(count:Int) {
		for (i in 0...count) {
			isolated(cycle);
			collect();
		}
	}

	static function useKept(use:Dynamic->Bool):Bool {
		var result = use(keep);
		keep = null;
		return result;
	}

	static function keepStage(take:Void->Dynamic, use:Dynamic->Bool):Bool {
		loadAndKeep(take);
		collect();
		var alive = live() == base + 1;
		return useKept(use) && alive;
	}

	static function kept(name:String, take:Void->Dynamic, use:Dynamic->Bool) {
		var ok = isolated(() -> keepStage(take, use));
		collect();
		Sys.println('$name: kept $ok, freed after ${live() == base}');
	}

	static function across():String {
		module = load();
		var cls = scriptClass("Script");
		var across = Reflect.field(cls, "across");
		cls = null;
		var result:String = Reflect.callMethod(null, across, [() -> {
			release(module);
			module = null;
			collect();
			duringCallback = live();
		}]);
		across = null;
		return result;
	}

	static function threaded():Bool {
		module = load();
		var spin = Reflect.field(scriptClass("Script"), "spin");
		var done = new sys.thread.Lock();
		var started = new sys.thread.Lock();
		var ok = true;
		sys.thread.Thread.create(() -> {
			var f = spin;
			spin = null;
			var expected = f(100);
			started.release();
			for (i in 0...200)
				if (f(100) != expected)
					ok = false;
			f = null;
			done.release();
		});
		started.wait();
		spin = null;
		release(module);
		module = null;
		for (i in 0...10)
			collect();
		done.wait();
		return ok;
	}

	static function resourceString():String {
		module = load();
		var text:String = call("resource", []);
		release(module);
		module = null;
		return text;
	}

	static function exceptionStack():Bool {
		module = load();
		var fail = Reflect.field(scriptClass("Script"), "fail");
		var caught = false;
		try {
			fail();
		} catch (e:Dynamic) {
			caught = true;
		}
		fail = null;
		release(module);
		module = null;
		return caught;
	}

	static function failedLoad():Bool {
		var data = bytes.sub(0, bytes.length >> 1);
		try {
			cpp.cppia.Module.fromData(data.getData());
			return false;
		} catch (e:Dynamic) {
			return true;
		}
	}

	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			collect();
			base = live();

			reloads(10);
			Sys.println('jit $jit: released modules freed: ${live() == base}');

			kept('jit $jit: instance', () -> Type.createInstance(scriptClass("Thing"), []), t -> t.get() == 8);
			kept('jit $jit: bound method', () -> Reflect.field(Type.createInstance(scriptClass("Thing"), []), "get"), f -> f() == 8);
			kept('jit $jit: static function', () -> Reflect.field(scriptClass("Script"), "twice"), f -> f(3) == 7);
			kept('jit $jit: local function', () -> call("makeAdder", [10]), f -> f(1) == 12);
			kept('jit $jit: enum value', () -> call("dot", []), e -> Std.string(e) == "Dot" && Type.enumIndex(e) == 0);
			kept('jit $jit: enum with arguments', () -> call("circle", [5]), e -> Std.string(e) == "Circle(5)" && Type.enumParameters(e)[0] == 5);
			kept('jit $jit: enum constructor', () -> call("circleConstructor", []), c -> Std.string(c(4)) == "Circle(4)");
			kept('jit $jit: class', () -> scriptClass("Thing"), c -> Type.createInstance(c, []).get() == 8 && Type.getClassName(c) == "Thing");
			var text = isolated(resourceString);
			collect();
			Sys.println('jit $jit: resource string outlives its module: ${live() == base && text == "cppia resource text"}');

			var result = isolated(across);
			collect();
			Sys.println('jit $jit: running code kept: ${duringCallback == base + 1 && result == "before:8:7:Dot:Circle(2)"}, freed after ${live() == base}');

			var ok = isolated(threaded);
			collect();
			Sys.println('jit $jit: running on a thread: $ok, freed after ${live() == base}');

			var caught = isolated(exceptionStack);
			collect();
			var freed = live() == base;
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			Sys.println('jit $jit: exception stack: ${caught && freed}, still readable ${jit || stack.indexOf("Script") >= 0}');

			var threw = isolated(failedLoad);
			collect();
			Sys.println('jit $jit: failed load freed: ${threw && live() == base}');

			reloads(20);
			var before = memory();
			reloads(100);
			var grown = (memory() - before) / (1 << 20);
			Sys.println('jit $jit: native memory stable: ${grown < 16}');
			if (grown >= 16)
				Sys.println('  grew ${Std.int(grown)} MB over 100 reloads');
		}
	}
}
