interface Shape {
	function area():Int;
}

class Base implements Shape {
	public function new() {}

	public function area():Int
		return 1;

	public function twice():Int
		return area() * 2;
}

class Square extends Base {
	var side:Int;

	public function new(side:Int) {
		super();
		this.side = side;
	}

	override public function area():Int
		return side * side;
}

class Script {
	static function leaf(n:Int):Int
		return n + 1;

	static function middle(n:Int):Int
		return leaf(n) * 2;

	static function fib(n:Int):Int
		return n < 2 ? n : fib(n - 1) + fib(n - 2);

	static function fails(n:Int):Int {
		if (n > 0)
			throw 'failed $n';
		return n;
	}

	static function catcher():String {
		try {
			fails(3);
			return "no throw";
		} catch (e:String) {
			return e;
		}
	}

	// Called by the host only
	public static function plusOne(n:Int):Int
		return n + 1;

	// Called from several threads at once, for the first time
	public static function work(k:Int):Int {
		var s = 0;
		for (i in 0...1000)
			s += step(i + k);
		return s;
	}

	static function step(n:Int):Int
		return n % 7;

	static function main() {
		Sys.println('a compiled function calls one not compiled yet: ${middle(4) == 10}');
		Sys.println('a function calls itself while it is first called: ${fib(15) == 610}');
		var shapes:Array<Base> = [new Base(), new Square(3)];
		Sys.println('virtual calls reach methods not compiled yet: ${shapes[0].twice() == 2 && shapes[1].twice() == 18}');
		var shape:Shape = new Square(4);
		Sys.println('interface calls reach methods not compiled yet: ${shape.area() == 16}');
		Sys.println('an exception leaves a function compiled on its first call: ${catcher() == "failed 3"}');
	}
}
