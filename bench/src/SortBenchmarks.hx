package;

import Benchmark.Rng;

/** Array<Int> sorted with a comparator closure. **/
class SortInt extends Benchmark {
	static inline var N = 200000;

	final source:Array<Int> = [];

	public function new() {
		super("sort_int", "elements", N, false, 2);
	}

	override public function setup() {
		var rng = new Rng(21);
		for (i in 0...N)
			source.push(rng.next() >> 1);
	}

	override public function run():Int {
		var a = source.copy();
		a.sort((x, y) -> x - y);
		for (i in 1...N)
			if (a[i - 1] > a[i])
				throw 'sort_int: out of order at $i';
		return (a[N >> 1] * 7 + a[N >> 2] + a[N - 1]) | 0;
	}
}

/** Array<String> sorted with Reflect.compare, the usual idiom. **/
class SortString extends Benchmark {
	static inline var N = 100000;

	final source:Array<String> = [];

	public function new() {
		super("sort_string", "elements", N, false, 2);
	}

	override public function setup() {
		var rng = new Rng(22);
		for (i in 0...N)
			source.push("s" + StringTools.hex(rng.next()));
	}

	override public function run():Int {
		var a = source.copy();
		a.sort(Reflect.compare);
		for (i in 1...N)
			if (a[i - 1] > a[i])
				throw 'sort_string: out of order at $i';
		var mid = a[N >> 1];
		var last:Int = mid.charCodeAt(mid.length - 1);
		var second:Int = a[0].charCodeAt(1);
		return (mid.length * 31 + last + second) | 0;
	}
}

class Item {
	public final key:Int;
	public final order:Int;

	public function new(key:Int, order:Int) {
		this.key = key;
		this.order = order;
	}
}

/** Objects sorted by an Int field, with repeated keys. **/
class SortObject extends Benchmark {
	static inline var N = 100000;

	final source:Array<Item> = [];

	public function new() {
		super("sort_object", "elements", N, false, 5);
	}

	override public function setup() {
		var rng = new Rng(23);
		for (i in 0...N)
			source.push(new Item(rng.below(10000), i));
	}

	override public function run():Int {
		var a = source.copy();
		a.sort((x, y) -> x.key - y.key);
		var sum = 0;
		for (i in 1...N) {
			if (a[i - 1].key > a[i].key)
				throw 'sort_object: out of order at $i';
			// Haxe doesn't promise a stable sort. The key at each position is the same
			// for any correct sort, so this sum doesn't depend on how ties are ordered
			sum = (sum + a[i].key * (i & 7)) | 0;
		}
		return sum;
	}
}
