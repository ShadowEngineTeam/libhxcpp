function main() {
	Compiled.run();
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	for (jit in [false, true]) {
		cpp.cppia.Host.enableJit(jit);
		try {
			cpp.cppia.Host.runFile(script);
		} catch (e:Dynamic) {
			Sys.println("error: " + e);
		}
	}
}

class Compiled {
	public static function run() {
		var a = 2147483647;
		var f:Float = a + 1;
		Sys.println(f);
		Sys.println("s" + (a + 1));
		var b = 65536;
		var g:Float = b * b;
		Sys.println(g);
		var c = -2147483647;
		var h:Float = c - 2;
		Sys.println(h);
		var d:Dynamic = a + 1;
		Sys.println(d);
		var x = 3, y = 4;
		var k:Float = x * y + x - y;
		Sys.println(k);
	}
}
