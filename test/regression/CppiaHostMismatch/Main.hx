import cpp.cppia.Host;
import cpp.cppia.Module;

// Built with HXCPP_CATCH_SEGV, as the Cppia host is. Each script fails in a
// way a script out of step with its host can; the host catches every one.
class Main {
	static var keep:Array<Dynamic> = [Thing];

	static function load(name:String):String {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), name + ".cppia"]);
		try {
			var module = Module.fromData(sys.io.File.getBytes(path).getData());
			module.boot();
			module.run();
			return "ran";
		} catch (e:Dynamic) {
			return "caught " + e;
		}
	}

	static function check(what:String, seen:String, expected:String) {
		if (seen != expected)
			Sys.stderr().writeString('$what: got $seen\n');
		Sys.println('$what: ${seen == expected}');
	}

	static function main() {
		for (jit in [false, true]) {
			Host.enableJit(jit);
			check('jit $jit: a call with the wrong argument count fails to load, naming it', load("argcount"),
				"caught Could not link Thing.add with 2 arguments: the host's takes 1");
			check('jit $jit: a const char * thrown by native code reaches the host', load("nativethrow"), "caught thrown by native code");
		}
		// The interpreter relies on the fault handler here, which jitted code
		// cannot throw through
		Host.enableJit(true);
		var seen = load("nullfield");
		if (seen.indexOf("caught") != 0)
			Sys.stderr().writeString('null field read: got $seen\n');
		Sys.println('jit true: a null field read reaches the host: ${seen.indexOf("caught") == 0}');
	}
}
