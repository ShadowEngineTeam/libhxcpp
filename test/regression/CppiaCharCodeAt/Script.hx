class Script {
	static function main() {
		var s = "hello";
		Sys.println("c" + s.charCodeAt(1));
		var f:Float = s.charCodeAt(1);
		Sys.println(f);
		Sys.println("c" + s.charCodeAt(99));
		var i:Int = s.charCodeAt(4);
		Sys.println(i);
	}
}
