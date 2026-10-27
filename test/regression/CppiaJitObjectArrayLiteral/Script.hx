class Item {
	public var value:Int;

	public function new(value:Int)
		this.value = value;
}

class Script {
	public static var kept:Array<Item>;

	public static function main() {
		kept = [new Item(1), new Item(2), null, new Item(4)];
	}
}
