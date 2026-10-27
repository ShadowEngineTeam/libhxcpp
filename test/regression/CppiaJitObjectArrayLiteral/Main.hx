import cpp.cppia.Host;
import cpp.cppia.Module;

// Under HXCPP_GC_GENERATIONAL, an array literal of objects failed to compile
// with the JIT, "Bad move target": its write barrier moved an untyped register.
// The script stores one in a static, and the host checks what it holds after
// collections, interpreted and with the JIT.
class Main {
	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			Host.enableJit(jit);
			var loaded = try {
				var module = Module.fromData(bytes.getData());
				module.boot();
				module.run();
				module;
			} catch (e:Dynamic) {
				Sys.stderr().writeString('jit $jit: $e\n');
				null;
			}
			Sys.println('jit $jit: the module loads: ${loaded != null}');
			if (loaded == null)
				continue;
			for (i in 0...3)
				cpp.vm.Gc.run(i == 2);
			var kept:Array<Dynamic> = Reflect.field(loaded.resolveClass("Script"), "kept");
			var values = [for (item in kept) item == null ? 0 : item.value];
			Sys.println('jit $jit: the array keeps its items: ${values.join(",") == "1,2,0,4"}');
			untyped loaded.release();
		}
	}
}
