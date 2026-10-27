// Each thread's cppia script stack was a fixed 128 KB, so a script that recursed
// a hundred levels with 1 KB of locals in each threw "Stack Overflow". Its size
// is now HXCPP_CPPIA_STACK_SIZE, which build.hxml sets to 256 KB, and
// __scriptable_cppia_set_stack_size changes it at run time. A stack reserves its
// size and commits memory as frames reach it. Script.check recurses through most
// of the size and then past it, interpreted and with the JIT, on this thread and
// on a thread started after the change.
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#ifndef HX_WINDOWS
#include <pthread.h>
#endif
// Recursing through 768 KB of script stack takes more native stack than the
// 128 KB musl gives a thread, so the thread gets 8 MB, as glibc gives
#ifdef HX_WINDOWS
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
#else
static void *runCallback(void *inCallback) {
 hx::NativeAttach attach; (*(Dynamic *)inCallback)();
 return 0;
}
static void runJoined(Dynamic callback) {
 pthread_attr_t attr;
 pthread_attr_init(&attr);
 pthread_attr_setstacksize(&attr, 8*1024*1024);
 pthread_t worker;
 pthread_create(&worker, &attr, runCallback, &callback);
 pthread_attr_destroy(&attr);
 hx::AutoGCFreeZone freeZone; pthread_join(worker, 0);
}
#endif
')
class Main {
	static function stackSize():Int
		return untyped __global__.__scriptable_cppia_stack_size();

	// Its context goes back to the pool when it ends, still at the define's size
	static function firstThread() {
		Sys.println("a thread gets the define's size: " + (stackSize() == Host.size));
	}

	// Takes the pooled context, whose stack the new size replaces. The JIT's
	// check runs first, so that its frames are the ones that commit the stack
	static function laterThread() {
		Sys.println("a later thread takes the new size: " + (stackSize() == Host.size));
		var checks = Host.checks.copy();
		checks.reverse();
		for (check in checks)
			check(Host.size);
	}

	static function main() {
		Host.size = 256 * 1024;
		Sys.println("the define sets the size: " + (stackSize() == Host.size));
		var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			try {
				cpp.cppia.Host.runFile(script);
			} catch (e:Dynamic) {
				Sys.println("error: " + e);
			}
		}
		untyped __cpp__("runJoined({0})", firstThread);

		Host.size = 768 * 1024;
		untyped __global__.__scriptable_cppia_set_stack_size(Host.size);
		Sys.println("this thread takes the new size: " + (stackSize() == Host.size));
		for (check in Host.checks)
			check(Host.size);
		untyped __cpp__("runJoined({0})", laterThread);
	}
}
