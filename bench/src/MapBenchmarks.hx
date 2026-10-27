package;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

/**
	Every map benchmark repeats the same N-key cycle on a fresh map:
	N sets, N hits, N misses, N/2 removes, then iterates the N/2 values
	left. That is 4N operations per cycle. N stays fixed so the map size
	(and cache behaviour) stays the same; REPS sizes the sample.

	Sums are order-independent, so a different hash order in either
	runtime doesn't change the checksum. get() returns Null<Int>, which
	hxcpp holds as Dynamic, so each hit is converted to Int before the
	arithmetic, as typical code would.
**/
class MapInt extends Benchmark {
	static inline var N = 200000;
	static inline var REPS = 6;

	final keys:Array<Int> = [];
	final misses:Array<Int> = [];

	public function new() {
		super("map_int", "map operations", N * 4 * REPS);
	}

	override public function setup() {
		// No overflow for i < 2N, and XOR with a constant keeps the keys distinct
		for (i in 0...N)
			keys.push(key(i));
		for (i in N...N * 2)
			misses.push(key(i));
	}

	public static inline function key(i:Int):Int {
		return (i * 2579) ^ 0x2b5f3c1d;
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...REPS)
			sum = (sum * 31 + cycle()) | 0;
		return sum;
	}

	function cycle():Int {
		var m = new IntMap<Int>();
		for (i in 0...N)
			m.set(keys[i], i);
		var sum = 0;
		for (i in 0...N) {
			var v = m.get(keys[i]);
			if (v != null)
				sum = (sum + (v : Int)) | 0;
		}
		for (i in 0...N)
			if (m.exists(misses[i]))
				sum++;
		for (i in 0...(N >> 1))
			m.remove(keys[i]);
		for (v in m)
			sum = (sum + v * 3) | 0;
		return sum;
	}
}

class MapString extends Benchmark {
	static inline var N = 200000;
	static inline var REPS = 4;

	final keys:Array<String> = [];
	final misses:Array<String> = [];

	public function new() {
		super("map_string", "map operations", N * 4 * REPS);
	}

	override public function setup() {
		for (i in 0...N)
			keys.push("key_" + StringTools.hex(MapInt.key(i)));
		for (i in N...N * 2)
			misses.push("key_" + StringTools.hex(MapInt.key(i)));
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...REPS)
			sum = (sum * 31 + cycle()) | 0;
		return sum;
	}

	function cycle():Int {
		var m = new StringMap<Int>();
		for (i in 0...N)
			m.set(keys[i], i);
		var sum = 0;
		for (i in 0...N) {
			var v = m.get(keys[i]);
			if (v != null)
				sum = (sum + (v : Int)) | 0;
		}
		for (i in 0...N)
			if (m.exists(misses[i]))
				sum++;
		for (i in 0...(N >> 1))
			m.remove(keys[i]);
		for (v in m)
			sum = (sum + v * 3) | 0;
		return sum;
	}
}

class MapKey {
	public final id:Int;

	public function new(id:Int) {
		this.id = id;
	}
}

class MapObject extends Benchmark {
	static inline var N = 200000;
	static inline var REPS = 1;

	final keys:Array<MapKey> = [];
	final misses:Array<MapKey> = [];

	public function new() {
		super("map_object", "map operations", N * 4 * REPS);
	}

	override public function setup() {
		for (i in 0...N)
			keys.push(new MapKey(i));
		for (i in N...N * 2)
			misses.push(new MapKey(i));
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...REPS)
			sum = (sum * 31 + cycle()) | 0;
		return sum;
	}

	function cycle():Int {
		var m = new ObjectMap<MapKey, Int>();
		for (i in 0...N)
			m.set(keys[i], i);
		var sum = 0;
		for (i in 0...N) {
			var v = m.get(keys[i]);
			if (v != null)
				sum = (sum + (v : Int)) | 0;
		}
		for (i in 0...N)
			if (m.exists(misses[i]))
				sum++;
		for (i in 0...(N >> 1))
			m.remove(keys[i]);
		for (v in m)
			sum = (sum + v * 3) | 0;
		return sum;
	}
}

/**
	An Int64-keyed map through the runtime's Int64 hash, which Haxe 4.3 has
	no Map class for (Haxe 5's Int64Map calls the same functions).
**/
class Int64Table {
	var h:Dynamic;

	public function new() {}

	public function setInt(key:haxe.Int64, value:Int):Void
		untyped __global__.__int64_hash_set_int(__cpp__("HX_MAP_THIS"), key, value);

	public function set(key:haxe.Int64, value:Dynamic):Void
		untyped __global__.__int64_hash_set(__cpp__("HX_MAP_THIS"), key, value);

	public inline function getInt(key:haxe.Int64):Int
		return untyped __global__.__int64_hash_get_int(h, key);

	public inline function getInt64(key:haxe.Int64):haxe.Int64
		return untyped __global__.__int64_hash_get_int64(h, key);

	public inline function exists(key:haxe.Int64):Bool
		return untyped __global__.__int64_hash_exists(h, key);

	public inline function remove(key:haxe.Int64):Bool
		return untyped __global__.__int64_hash_remove(h, key);
}

/**
	Int64 keys that pack an (x, y) cell of a 256 x 256 grid, the usual way
	to key a map by coordinates: N sets, N hits, N misses, N/2 removes.
**/
class MapInt64 extends Benchmark {
	static inline var SIDE = 256;
	static inline var N = SIDE * SIDE;
	static inline var REPS = 4;

	final keys:Array<haxe.Int64> = [];
	final misses:Array<haxe.Int64> = [];

	public function new() {
		super("map_int64", "map operations", N * 3.5 * REPS);
	}

	override public function setup() {
		for (x in 0...SIDE)
			for (y in 0...SIDE) {
				keys.push(haxe.Int64.make(x, y));
				misses.push(haxe.Int64.make(x + SIDE, y));
			}
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...REPS)
			sum = (sum * 31 + cycle()) | 0;
		return sum;
	}

	function cycle():Int {
		var m = new Int64Table();
		for (i in 0...N)
			m.setInt(keys[i], i);
		var sum = 0;
		for (i in 0...N)
			sum = (sum * 7 + m.getInt(keys[i])) | 0;
		for (i in 0...N)
			if (m.exists(misses[i]))
				sum++;
		for (i in 0...(N >> 1))
			if (m.remove(keys[i]))
				sum++;
		return sum;
	}
}

/**
	Int64 values stored through the Dynamic setter, as generic code stores
	them, in maps that stay alive across collections, then read back typed.
**/
class MapInt64Values extends Benchmark {
	static inline var N = 200000;
	static inline var MAPS = 4;

	final keys:Array<haxe.Int64> = [];

	public function new() {
		super("map_int64_values", "map operations", N * 2 * MAPS);
	}

	override public function setup() {
		for (i in 0...N)
			keys.push(haxe.Int64.make(i >> 10, i * 0x9E3779B1));
	}

	override public function run():Int {
		var maps = [for (m in 0...MAPS) new Int64Table()];
		for (m in 0...MAPS) {
			var map = maps[m];
			for (i in 0...N) {
				var value:Dynamic = haxe.Int64.make(m + 1, i);
				map.set(keys[i], value);
			}
		}
		var sum = 0;
		for (m in 0...MAPS)
			for (i in 0...N) {
				var v = maps[m].getInt64(keys[i]);
				sum = (sum + v.low + v.high) | 0;
			}
		return sum;
	}
}
