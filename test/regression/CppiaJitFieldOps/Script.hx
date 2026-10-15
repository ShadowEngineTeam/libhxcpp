class Counter {
	public var calls = 0;
	public var amount:Float = 0.5;

	public function new() {}

	public function tick() {
		calls++;
	}

	public function grow() {
		amount++;
	}

	public function next() {
		return calls++;
	}
}

class Script {
	static var shared:Float = 9;

	public static function main() {
		var c = new Counter();
		c.tick();
		c.tick();
		c.tick();
		c.grow();
		Sys.println(c.calls + " " + c.amount + " " + c.next() + " " + c.calls);

		var x:Float = 5;
		x /= 4;
		c.amount /= 3;
		shared /= 2;
		var a:Array<Float> = [7];
		a[0] /= 2;
		Sys.println(x + " " + c.amount + " " + shared + " " + a[0]);
	}
}
