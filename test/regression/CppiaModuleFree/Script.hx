class Thing {
	public var value:Int;

	public function new()
		value = 7;

	public function get()
		return value + Script.offset;
}

enum Shape {
	Dot;
	Circle(r:Int);
}

@:build(Bulk.build(80))
class BulkA {}

@:build(Bulk.build(80))
class BulkB {}

class Script {
	public static var offset = 1;
	public static var big:haxe.io.Bytes;

	public static function main() {
		big = haxe.io.Bytes.alloc(1 << 20);
		big.set(0, BulkA.all() + BulkB.all());
	}

	public static function twice(x:Int)
		return x * 2 + offset;

	public static function makeAdder(n:Int):Int->Int
		return x -> x + n + offset;

	public static function dot():Shape
		return Dot;

	public static function circle(r:Int):Shape
		return Circle(r);

	public static function circleConstructor():Dynamic
		return Circle;

	public static function resource()
		return haxe.Resource.getString("res");

	public static function fail() {
		inner();
	}

	static function inner() {
		throw "script error";
	}

	public static function across(callback:Void->Void):String {
		var before = "before";
		step(callback);
		var thing = new Thing();
		return before + ":" + thing.get() + ":" + twice(3) + ":" + Std.string(Dot) + ":" + Std.string(Circle(2));
	}

	static function step(callback:Void->Void) {
		callback();
	}

	public static function spin(n:Int):Int {
		var total = 0;
		for (i in 0...n)
			total += twice(i) % 7;
		return total;
	}
}
