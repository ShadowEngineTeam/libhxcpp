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
