class Script {
	static var field:String = "f";

	static function main() {
		var s = "a";
		var n:String = null;
		s += n;
		Sys.println(s);
		var e = "";
		e += "";
		Sys.println((e == null) + " " + e.length);
		var t:String = null;
		t += "x";
		Sys.println(t);
		field += n;
		Sys.println(field);
	}
}
