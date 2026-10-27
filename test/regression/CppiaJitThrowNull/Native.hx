// Host functions for the script, so that what it throws crosses native frames
class Native {
	// What a native catch gets from f
	public static function call(f:Void->Void):String {
		try {
			f();
		} catch (e:Dynamic) {
			return e == null ? "null" : "'" + e + "'";
		}
		return "nothing";
	}

	public static function raise(value:Dynamic):Void {
		throw value;
	}

	// Lets whatever f throws through to the caller
	public static function pass(f:Void->Void):Void {
		f();
	}
}
