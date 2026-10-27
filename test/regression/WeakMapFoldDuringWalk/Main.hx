import haxe.ds.WeakMap;

class Key {
	public var id:Int;

	public function new(id:Int) this.id = id;
}

// A collection that finds most of a weak map's keys gone folds its buckets
// down, moving the entries of the upper buckets into the lower ones
// (libhxcpp #204). A walk over the map that allocates, as converting it to
// another value type does, can be in the middle of the buckets when that
// collection comes: the entries moved into buckets it had passed were never
// visited, and the converted map lost them without a word.
class Main {
	static inline var COUNT = 200000;
	static inline var KEPT_EVERY = 16;

	// Each round converts a map that holds many dead keys, which is when a
	// collection during the conversion folds the old map
	static function round(kept:Array<Key>):Int {
		var map = new WeakMap<Key, Dynamic>();
		for (i in 0...COUNT) {
			var key = new Key(i);
			map.set(key, i);
			if (i % KEPT_EVERY == 0)
				kept.push(key);
		}
		// Int values so far; a String converts the store to Dynamic values,
		// walking the old one
		map.set(kept[0], "converted");
		var lost = 0;
		for (i in 1...kept.length) {
			var value:Null<Int> = map.get(kept[i]);
			if (value == null || value != kept[i].id)
				lost++;
		}
		return lost;
	}

	static function main() {
		var lost = 0;
		for (r in 0...12) {
			var kept = [];
			var n = round(kept);
			if (n > 0)
				Sys.stderr().writeString('round $r: $n of ${kept.length - 1} kept keys lost\n');
			lost += n;
		}
		Sys.println("converting a weak map keeps every live key: " + (lost == 0));
	}
}
