// The jit's write barrier compares an object's mark with the thread's mark ID,
// which the main thread did not set until the first collection. Left at 0, it
// took every nursery object for an old one and flagged it remembered. A flagged nursery object hid
// the nursery objects after it from the stack scan, which then freed them while
// they were in use: the closure passed to Reflect.callMethod was freed while its
// function ran Gc.compact() (HaxeFoundation/hxcpp#1196).
class Main {
	static function main() {
		cpp.cppia.Host.enableJit(true);
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var module = cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		module.boot();

		// Before any collection, the main thread's mark ID must already be the collector's
		var inStep:Bool = untyped __cpp__("hx::CppiaCtx::getCurrent()->byteMarkId == hx::gByteMarkID");
		Sys.println('the thread mark ID matches the collector before a collection: $inStep');

		// Jitted code sets a field of a new object
		var holder = Type.createInstance(module.resolveClass("Holder"), []);
		var remembered:Bool = untyped __cpp__("(((unsigned char *){0}.mPtr)[HX_ENDIAN_MARK_ID_BYTE] & HX_GC_REMEMBERED) != 0", holder);
		Sys.println('a new object is flagged remembered: $remembered');

		var cls = module.resolveClass("Worker");
		var bad = 0;
		for (round in 0...30) {
			var w = Type.createInstance(cls, []);
			var r:Int = Reflect.callMethod(w, Reflect.field(w, "work"), [100]);
			if (r != 499500 + 100)
				bad++;
		}
		Sys.println('calls that lost their closure: $bad');
	}
}
