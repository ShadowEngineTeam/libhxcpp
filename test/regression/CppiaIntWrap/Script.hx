class Script {
	static function run() {
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

	static function main() {
		run();
	}
}
