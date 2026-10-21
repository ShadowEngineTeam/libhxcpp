class Script {
	static function attempt(label:String, f:Void->Dynamic) {
		try {
			Sys.println(label + " = " + f());
		} catch (e:Dynamic) {
			Sys.println(label + " throws");
		}
	}

	static function run() {
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
		var f:Float = 2.5;
		var n:Int = 3;
		var s:String = null;
		var b:Bool = true;
		attempt("typed 2.5 Float", () -> cast(f, Float));
		attempt("typed 3 Float", () -> cast(n, Float));
		attempt("typed 3 Int", () -> cast(n, Int));
		attempt("typed null String", () -> cast(s, String));
		attempt("typed true Bool", () -> cast(b, Bool));
	}

	static function main() {
		run();
	}
}
