@:cppFileCode("#include <hx/Scriptable.h>")
class Main {
	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var module = cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		module.boot();
		var cls = module.resolveClass("Worker");
		var total = 0;
		for (i in 0...20) {
			var worker = Type.createInstance(cls, []);
			total += Reflect.callMethod(worker, Reflect.field(worker, "work"), [i]);
		}
		Sys.println(total);
	}
}
