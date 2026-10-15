class Script {
	static function pair(a:Int, b:Int) {
		return a + b;
	}

	public static function main() {
		try {
			Reflect.callMethod(null, pair, [0, 1, 2]);
			Sys.println("too many returned");
		} catch (e:Dynamic) {
			Sys.println("too many threw");
		}
		var f:Dynamic = pair;
		try {
			f(1, 2, 3, 4, 5, 6, 7);
			Sys.println("seven returned");
		} catch (e:Dynamic) {
			Sys.println("seven threw");
		}
	}
}
