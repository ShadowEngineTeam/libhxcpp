import sys.io.Process;

// On POSIX, Process.close waited for the child once without blocking and then
// forgot its pid, so a child still running at close stayed a zombie for as
// long as the parent lived. The GC finalizer did the same. Each case below
// starts children, lets them go, and checks that every one is gone (reaped,
// so kill(pid, 0) fails) within a few seconds, and that close does not wait.
// Windows has no zombies and prints the same lines. openfl/libhxcpp#180
@:cppFileCode('
#include <hx/Native.h>
#include <thread>
#include <exception>
#ifndef HX_WINDOWS
#include <signal.h>
#include <errno.h>
#endif
static bool childExists(int inPid)
{
#ifdef HX_WINDOWS
	return false;
#else
	return ::kill(inPid, 0) == 0 || errno != ESRCH;
#endif
}
static void runOnJoinedWorker(Dynamic action)
{
	struct ErrorRoot {
		Dynamic value;
		ErrorRoot() { hx::GCAddRoot(&value.mPtr); }
		~ErrorRoot() { hx::GCRemoveRoot(&value.mPtr); }
	} error;
	std::exception_ptr nativeError;
	hx::AutoGCFreeZone zone;
	std::thread worker([&]() {
		hx::NativeAttach attached;
		try { action(); }
		catch (Dynamic e) { error.value = e; }
		catch (...) { nativeError = std::current_exception(); }
	});
	worker.join();
	zone.close();
	if (nativeError) std::rethrow_exception(nativeError);
	if (error.value.mPtr) hx::Throw(error.value);
}
')
class Main {
	static function exists(pid:Int):Bool {
		return untyped __cpp__("childExists({0})", pid);
	}

	// Polls until none of the pids exists, for up to five seconds
	static function allGone(pids:Array<Int>):Bool {
		var deadline = Sys.time() + 5;
		while (Sys.time() < deadline) {
			var left = 0;
			for (pid in pids)
				if (exists(pid))
					left++;
			if (left == 0)
				return true;
			Sys.sleep(0.05);
		}
		return false;
	}

	static function start(seconds:Float):Process {
		if (Sys.systemName() == "Windows")
			return new Process("cmd", ["/c", "exit"]);
		return new Process("/bin/sh", ["-c", "sleep " + seconds]);
	}

	static function startAndDrop(seconds:Float, pids:Array<Int>, refs:Array<cpp.vm.WeakRef<Dynamic>>) {
		// A returned function can leave conservative roots on the current stack.
		// Join after the worker detaches, so GC cannot retain the child that way.
		var action:Dynamic = function() {
			var p = start(seconds);
			pids.push(p.getPid());
			refs.push(new cpp.vm.WeakRef<Dynamic>(@:privateAccess p.p));
		};
		untyped __cpp__("runOnJoinedWorker({0})", action);
	}

	static function main() {
		// Closed while the child still runs
		var p = start(0.3);
		var pid = p.getPid();
		var t0 = Sys.time();
		p.close();
		var closeTook = Sys.time() - t0;
		Sys.println("close before exit: " + (allGone([pid]) ? "reaped" : "left a zombie"));
		Sys.println("close did not wait: " + (closeTook < 0.25));

		// Closed after the child exited
		var p = start(0);
		var pid = p.getPid();
		Sys.sleep(0.5);
		p.close();
		Sys.println("close after exit: " + (allGone([pid]) ? "reaped" : "left a zombie"));

		// Never closed: the finalizer cleans up while the child still runs
		var pids = [];
		var refs = [];
		startAndDrop(0.3, pids, refs);
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		Sys.println("process handle collected: " + (refs[0].get() == null));
		Sys.println("collected before exit: " + (allGone(pids) ? "reaped" : "left a zombie"));

		// Many short-lived children closed at once
		var pids = [];
		for (i in 0...40) {
			var c = start(0.05);
			pids.push(c.getPid());
			c.close();
		}
		Sys.println("40 closed children: " + (allGone(pids) ? "all reaped" : "zombies left"));
	}
}
