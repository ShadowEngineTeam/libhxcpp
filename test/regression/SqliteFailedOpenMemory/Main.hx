@:cppFileCode('
extern "C" long long sqlite3_memory_used(void);
')
class Main {
	static function failOpen(path:String):Bool {
		try {
			var db = sys.db.Sqlite.open(path);
			db.close();
			return false;
		} catch (e:Dynamic) {
			return true;
		}
	}
	static function main() {
		var parent = "missing-sqlite-parent-" + Std.string(Date.now().getTime());
		if (sys.FileSystem.exists(parent)) throw "Fixture directory already exists";
		var path = haxe.io.Path.join([Sys.getCwd(), parent, "data.sqlite"]);
		if (!failOpen(path)) throw "Open unexpectedly succeeded";
		cpp.vm.Gc.run(true);
		var before:Float = untyped __cpp__("(double)sqlite3_memory_used()");
		var failures = 0;
		for (i in 0...128) if (failOpen(path)) failures++;
		for (i in 0...3) cpp.vm.Gc.run(true);
		var after:Float = untyped __cpp__("(double)sqlite3_memory_used()");
		Sys.println("failed opens: " + failures);
		Sys.println("failed open memory released: " + (after - before < 4096));
	}
}
