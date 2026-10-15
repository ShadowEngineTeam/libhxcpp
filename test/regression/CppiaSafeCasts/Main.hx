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
	static function attempt(label:String, f:Void->Dynamic) {
		try {
			Sys.println(label + " = " + f());
		} catch (e:Dynamic) {
			Sys.println(label + " throws");
		}
	}

	public static function run() {
		var abc:Dynamic = "abc";
		var half:Dynamic = 1.5;
		var seven:Dynamic = 7;
		var yes:Dynamic = true;
		var none:Dynamic = null;
		attempt("abc Int", () -> cast(abc, Int));
		attempt("1.5 Int", () -> cast(half, Int));
		attempt("7 String", () -> cast(seven, String));
		attempt("7 Int", () -> cast(seven, Int));
		attempt("7 Float", () -> cast(seven, Float));
		attempt("1.5 Float", () -> cast(half, Float));
		attempt("true Bool", () -> cast(yes, Bool));
		attempt("7 Bool", () -> cast(seven, Bool));
		attempt("abc String", () -> cast(abc, String));
		attempt("null String", () -> cast(none, String));
		attempt("null Int", () -> cast(none, Int));
		attempt("null Float", () -> cast(none, Float));
		attempt("null Bool", () -> cast(none, Bool));
		var caught = try {
			throw (none : Int);
		} catch (s:Int) {
			"Int " + s;
		} catch (e:Dynamic) {
			"Dynamic";
		}
		Sys.println("caught " + caught);
		var i:Int = 0;
		try {
			i = cast(half, Int);
		} catch (e:Dynamic) {
			i = -1;
		}
		Sys.println("typed " + i);
	}
}
