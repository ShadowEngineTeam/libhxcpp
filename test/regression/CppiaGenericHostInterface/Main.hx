// A script class that implements a host interface with type parameters gets
// its arguments as the host compiled them, every K and V an object, while its
// own functions read typed String and Int arguments. Calls through the
// interface read garbage: exists was false, get was null and set could crash.
// The interface slot now gets an adapter that converts the arguments and the
// result. openfl/libhxcpp#130
function main() {
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	for (jit in [false, true]) {
		cpp.cppia.Host.enableJit(jit);
		try {
			cpp.cppia.Host.runFile(script);
			var map = Holder.map;
			Sys.println('host: exists z ${map.exists("z")}, get z ${map.get("z")}');
			map.set("a", 3);
			Sys.println('host: exists a ${map.exists("a")}, get a ${map.get("a")}, exists q ${map.exists("q")}');
			Sys.println('host: scale a ${map.scale("a", 1.5, false)}, rounded ${map.scale("a", 1.5, true)}');
			try {
				map.exists("boom");
				Sys.println("host: no exception");
			} catch (e:Dynamic) {
				Sys.println('host: caught $e');
			}
		} catch (e:Dynamic) {
			Sys.println("error: " + e);
		}
	}
}
