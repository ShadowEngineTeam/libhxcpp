import cpp.vm.Gc;

class Main {
	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			var keepThing:Dynamic = null;
			var keepMethod:Dynamic = null;
			var keepClass:Class<Dynamic> = null;
			var lookups = true;
			for (i in 0...30) {
				var module = cpp.cppia.Module.fromData(bytes.getData());
				module.boot();
				module.run();
				if (i == 0) {
					keepClass = module.resolveClass("Thing");
					keepThing = Type.createInstance(keepClass, []);
					keepMethod = Reflect.field(keepThing, "get");
				}
				if (Type.resolveClass("Thing") == null)
					lookups = false;
				untyped module.release();
				if (Type.resolveClass("Thing") != null)
					lookups = false;
				module = null;
				Gc.run(true);
			}
			Gc.run(true);
			var largeMb = Gc.memInfo64(Gc.MEM_INFO_LARGE) / (1 << 20);
			Sys.println('jit $jit: released statics collected: ${largeMb < 24}');
			Sys.println('jit $jit: class registered only while loaded: $lookups');
			Sys.println('jit $jit: first generation still works: ${keepThing.get() == 8 && keepMethod() == 8 && Type.getInstanceFields(keepClass).indexOf("value") >= 0}');
		}
	}
}
