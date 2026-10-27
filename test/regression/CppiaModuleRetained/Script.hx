class Thing {
	public var value:Int;

	public function new(value:Int)
		this.value = value;

	public function get()
		return value;
}

class Other {
	public function new() {}
}

class Script {
	// Cleared by release, so not among what keeps the module loaded
	public static var kept:Array<Other>;

	public static function adder(by:Int):Int->Int
		return n -> n + by;

	public static function main() {
		kept = [new Other(), new Other()];
	}
}
