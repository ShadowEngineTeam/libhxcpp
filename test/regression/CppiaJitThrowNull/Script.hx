class Script {
	static function show(e:Dynamic):String {
		return e == null ? "null" : "'" + e + "'";
	}

	static function thrower(value:Dynamic):Void {
		throw value;
	}

	static function deep(n:Int, value:Dynamic):Void {
		if (n == 0)
			thrower(value);
		else
			deep(n - 1, value);
	}

	static function rethrow(value:Dynamic):Void {
		try {
			deep(2, value);
		} catch (e:Dynamic) {
			throw e;
		}
	}

	static function unmatched(value:Dynamic):Void {
		try {
			deep(2, value);
		} catch (s:String) {
			Sys.println("  inner String " + show(s));
		} catch (i:Int) {
			Sys.println("  inner Int " + i);
		}
	}

	// Throws value one way and says which catch, the typed ones first, got it
	static function check(name:String, value:Dynamic, way:String) {
		var caught = try {
			switch (way) {
				case "direct":
					throw value;
				// Several script frames down
				case "deep":
					deep(4, value);
				case "rethrow":
					rethrow(value);
				case "unmatched":
					unmatched(value);
				// Through a local function
				case "closure":
					var f = () -> deep(2, value);
					f();
				case "closure catch":
					var f = () -> try {
						deep(2, value);
					} catch (e:Dynamic) {
						throw e;
					};
					f();
				// Through a host frame, then thrown by the host
				case "native":
					Native.pass(() -> deep(2, value));
				case "host":
					Native.raise(value);
				// A host function called as a value
				case "host closure":
					var f = Native.raise;
					f(value);
				// From the host to the script and back
				case "host frames":
					Native.pass(() -> Native.raise(value));
			}
			"nothing";
		} catch (s:String) {
			"String " + show(s);
		} catch (i:Int) {
			"Int " + i;
		} catch (x:Float) {
			"Float " + x;
		} catch (b:Bool) {
			"Bool " + b;
		} catch (e:Dynamic) {
			"Dynamic " + show(e);
		}
		Sys.println(name + " " + way + ": " + caught);
	}

	public static function main() {
		try {
			throw null;
		} catch (e:Dynamic) {
			Sys.println("throw null: Dynamic " + show(e));
		}

		var values:Array<Dynamic> = [null, "", "abc", 7, 1.5, true, [1, 2]];
		var names = ["null", "empty", "abc", "7", "1.5", "true", "[1,2]"];
		for (i in 0...values.length)
			for (way in [
				"direct", "deep", "rethrow", "unmatched", "closure", "closure catch", "native", "host", "host closure", "host frames"
			])
				check(names[i], values[i], way);

		Sys.println("native catch null: " + Native.call(() -> deep(2, null)));
		Sys.println("native catch empty: " + Native.call(() -> deep(2, "")));
		Sys.println("native catch host null: " + Native.call(() -> Native.raise(null)));

		// Leaves the script for the host's catch
		deep(2, null);
		Sys.println("not thrown");
	}
}
