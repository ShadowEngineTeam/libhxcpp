class Script {
	static function sum(a:Float, b:Float):Float {
		var local = a + b;
		return local;
	}

	static function main() {
		Sys.println("script: " + sum(0.1, 0.2) + " " + sum(1 / 3, 0) + " " + sum(1e-300, 0));
		Sys.println("host from script: " + Host.combine(0.1, 1e-17) + " " + Host.combine(1 / 3, 0));
		Host.fromScript = function(a:Float, b:Float):Float return a / b;
	}
}
