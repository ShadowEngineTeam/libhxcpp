// The same four fields, declared with the Ints between the pointers and
// declared with the pointers first
class Mixed {
	public var i:Int;
	public var p:Dynamic;
	public var j:Int;
	public var q:Dynamic;

	public function new(n:Int) {
		i = n;
		p = this;
		j = n + 1;
		q = null;
	}

	public function sum():Int
		return i + j + (p == this ? 1 : 0) + (q == null ? 1 : 0);
}

class Grouped {
	public var p:Dynamic;
	public var q:Dynamic;
	public var i:Int;
	public var j:Int;

	public function new(n:Int) {
		i = n;
		p = this;
		j = n + 1;
		q = null;
	}

	public function sum():Int
		return i + j + (p == this ? 1 : 0) + (q == null ? 1 : 0);
}

class Script {
	public static var mixed:Array<Mixed>;
	public static var grouped:Array<Grouped>;

	public static function main() {
		mixed = [for (n in 0...1000) new Mixed(n)];
		grouped = [for (n in 0...1000) new Grouped(n)];
	}
}
