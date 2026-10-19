class ScriptMap implements HostMap<String, Int, Float> {
	var values = new Map<String, Int>();

	public function new() {}

	public function exists(key:String):Bool {
		if (key == "boom")
			throw "thrown by the script";
		return values.exists(key);
	}

	public function get(key:String):Null<Int>
		return values.get(key);

	public function set(key:String, value:Int):Void
		values.set(key, value);

	public function scale(key:String, by:Float, round:Bool):Float {
		var v = values.get(key) * by;
		return round ? Math.round(v) : v;
	}
}

class Script {
	static function main() {
		var map = new ScriptMap();
		map.set("z", 26);
		Holder.map = map;
		// The script calling through the host interface too
		var asInterface:HostMap<String, Int, Float> = map;
		Sys.println('script: get z ${asInterface.get("z")}, exists q ${asInterface.exists("q")}');
	}
}
