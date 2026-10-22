class Script {
	static function add(a:Int, b:Int):Int {
		var sum = a + b;
		sum = sum * 10;
		return sum;
	}

	static function main() {
		var x = 1;
		var y = add(x, 2);
		var z = y + 1;
		Sys.println("y=" + y + " z=" + z);
	}
}
