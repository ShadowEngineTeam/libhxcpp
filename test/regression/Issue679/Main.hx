class Key {
	public var id:Int;

	public function new(id:Int) {
		this.id = id;
	}
}

function main() {
	var map = new haxe.ds.ObjectMap<Key, Int>();
	var keys = [];
	for (i in 0...20000) {
		var k = new Key(i);
		keys.push(k);
		map.set(k, i);
	}
	var lost = 0;
	for (round in 0...20) {
		var garbage = [for (i in 0...50000) new Key(-i)];
		garbage = null;
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.compact();
		for (k in keys)
			if (map.get(k) != k.id)
				lost++;
	}
	Sys.println("lost " + lost);
}
