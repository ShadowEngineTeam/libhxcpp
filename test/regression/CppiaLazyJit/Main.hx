// Under the JIT, a script function compiles when it is first called rather than when
// its module loads. Compiled code calls a function not compiled yet through a check
// that compiles it, and calls through a vtable do the same. Threads that first call
// one function at the same time compile it once, and each gets its result.
class Main {
	static function main() {
		cpp.cppia.Host.enableJit(true);
		var active:Bool = untyped __cpp__("__scriptable_cppia_jit_active()");
		Sys.println('the JIT is on: $active');

		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var module = cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		module.boot();
		module.run();

		var cls = module.resolveClass("Script");
		var plusOne = Reflect.field(cls, "plusOne");
		var r:Int = Reflect.callMethod(cls, plusOne, [41]);
		Sys.println('the host calls a script function not compiled yet: ${r == 42}');

		var work = Reflect.field(cls, "work");
		var threads = 8;
		var done = new sys.thread.Lock();
		var mutex = new sys.thread.Mutex();
		var good = 0;
		for (t in 0...threads)
			sys.thread.Thread.create(() -> {
				var r:Int = Reflect.callMethod(cls, work, [t]);
				mutex.acquire();
				if (r == expected(t))
					good++;
				mutex.release();
				done.release();
			});
		for (_ in 0...threads)
			done.wait();
		Sys.println('threads that first call one function at once each get its result: ${good == threads}');
	}

	static function expected(k:Int):Int {
		var s = 0;
		for (i in 0...1000)
			s += (i + k) % 7;
		return s;
	}
}
