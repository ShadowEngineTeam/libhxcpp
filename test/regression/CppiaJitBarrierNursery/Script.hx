class Holder {
	public var value:Array<Int>;

	public function new() {
		value = [1];
	}
}

class Worker {
	public var data:Array<Int>;

	public function new() {
		data = [for (i in 0...1000) i];
	}

	public function work(n:Int):Int {
		cpp.vm.Gc.compact();
		var sum = 0;
		for (x in data)
			sum += x;
		var f = () -> sum + n;
		cpp.vm.Gc.compact();
		return f();
	}
}

class Script {
	static function main() {}
}
