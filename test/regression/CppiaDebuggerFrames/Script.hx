class Script {
	var label:String;

	function new()
		label = "probe";

	function probe(a:Int, b:String):String {
		var c = a * 2;
		var seen = Inspect.caller("probe");
		return seen + (c > 0 ? "" : "");
	}

	static function staticProbe(x:Float):String {
		var y = x + 1;
		var seen = Inspect.caller("staticProbe");
		return seen + (y > 0 ? "" : "");
	}

	static function main() {
		Sys.println("method: " + new Script().probe(21, "two"));
		Sys.println("static: " + staticProbe(1.5));
	}
}
