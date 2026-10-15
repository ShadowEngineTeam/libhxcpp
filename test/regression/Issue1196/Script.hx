class Worker {
	public function new() {}

	public function work(i:Int):Int {
		var junk = [for (j in 0...10000) "s" + j];
		cpp.vm.Gc.compact();
		var f = function(x:Int) return x + junk.length - 10000;
		return f(i);
	}
}

class Script {
	static function main() {}
}
