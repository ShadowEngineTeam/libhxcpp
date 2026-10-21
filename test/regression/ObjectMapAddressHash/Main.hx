import cpp.vm.Gc;

class Key {
	public var n:Int;

	public function new(n:Int)
		this.n = n;
}

// Without the moving collector an ObjectMap key now hashes by its address
// instead of a global object id. Keys must still be found after collections,
// and a weak map must not match a new object allocated where a collected key
// used to be.
function main() {
	var keys = [for (i in 0...50000) new Key(i)];
	var map = new haxe.ds.ObjectMap<Key, Int>();
	for (k in keys)
		map.set(k, k.n);
	for (round in 0...3) {
		var garbage = [for (i in 0...100000) new Key(i)];
		garbage = null;
		Gc.run(true);
	}
	var found = true;
	for (k in keys)
		if (map.get(k) != k.n)
			found = false;
	for (i in 0...25000)
		map.remove(keys[i * 2]);
	for (i in 0...keys.length)
		if (map.exists(keys[i]) != (i % 2 == 1))
			found = false;
	Sys.println("keys found after collections: " + found);

	var weak = new haxe.ds.WeakMap<Key, Int>();
	var held = [for (i in 0...1000) new Key(i)];
	for (i in 0...20000)
		weak.set(i < 1000 ? held[i] : new Key(i), i);
	Gc.run(true);
	Gc.run(true);
	var stale = false;
	for (i in 0...200000)
		if (weak.exists(new Key(i)))
			stale = true;
	var kept = true;
	for (i in 0...1000)
		if (weak.get(held[i]) != i)
			kept = false;
	Sys.println("weak map keeps live keys: " + kept + ", matches no new object: " + !stale);
}
