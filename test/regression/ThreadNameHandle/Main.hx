@:cppFileCode('#include <hx/thread/Thread.hpp>')
class Main {
	static function current():Dynamic
		return untyped __cpp__('::Dynamic(::hx::thread::Thread_obj::current())');

	static function getName(t:Dynamic):String
		return untyped __cpp__('::hx::thread::Thread({0})->getName()', t);

	static function setName(t:Dynamic, name:String)
		untyped __cpp__('::hx::thread::Thread({0})->setName({1})', t, name);

	static function main() {
		// Only MSVC Windows builds name threads
		if (#if mingw true #else Sys.systemName() != "Windows" #end) {
			Sys.println("main-thread");
			Sys.println("renamed");
			return;
		}
		var mainThread = current();
		setName(mainThread, "main-thread");
		var lock = new sys.thread.Lock();
		var seen = "";
		sys.thread.Thread.create(() -> {
			setName(current(), "worker");
			seen = getName(mainThread);
			setName(mainThread, "renamed");
			lock.release();
		});
		lock.wait();
		Sys.println(seen);
		Sys.println(getName(current()));
	}
}
