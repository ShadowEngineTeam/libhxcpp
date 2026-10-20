import haxe.CallStack;

@:cppFileCode('
struct CleanupGuard
{
   ::Dynamic cleanup;
   ~CleanupGuard() { if (cleanup.mPtr) cleanup(); }
};
static void runWithCleanup(::Dynamic action, ::Dynamic cleanup)
{
   CleanupGuard guard;
   guard.cleanup = cleanup;
   action();
}
')
class Main {
	static var cleanups = 0;

	static function wrapper(cleanup:Dynamic) {
		untyped __cpp__('runWithCleanup({0}, {1})', () -> throw "boom", cleanup);
	}

	static function frames(cleanup:Dynamic):Int {
		try {
			wrapper(cleanup);
		} catch (e:Dynamic) {
			return CallStack.exceptionStack().length;
		}
		return -1;
	}

	static function noteCleanup() {
		cleanups++;
	}

	static function catchingCleanup() {
		cleanups++;
		try {
			throw "inner";
		} catch (e:Dynamic) {}
	}

	static function main() {
		var control = frames(null);
		Sys.println("cleanup keeps every frame: " + (frames(noteCleanup) == control));
		Sys.println("catching cleanup keeps every frame: " + (frames(catchingCleanup) == control));
		Sys.println("cleanup calls: " + cleanups);
		var swallowed = untyped __cpp__('[]{ try { ::hx::Throw(HX_CSTRING("inner")); } catch(...) {} return 0; }()');
		Sys.println("after a swallowed throw: " + (frames(null) == control));
		if (Sys.getEnv("SHOW_FRAMES") != null)
			Sys.println(control + " " + CallStack.toString(CallStack.exceptionStack()));
	}
}
