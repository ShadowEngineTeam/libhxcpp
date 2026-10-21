class Thing {
	public var value:Int;

	public function new()
		value = 7;

	public function get()
		return value + Script.offset;
}

class Script {
	public static var offset = 1;
	public static var big:haxe.io.Bytes;

	public static function main() {
		big = haxe.io.Bytes.alloc(4 << 20);
		big.set(0, 1);
	}
}
