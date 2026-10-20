package;

import Benchmark.Rng;
import haxe.Timer;
import haxe.io.Bytes;

class Point {
	public var x:Int;
	public var y:Int;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

/** Small objects, almost all short-lived: the last 1024 stay reachable. **/
class AllocSmall extends Benchmark {
	static inline var N = 20000000;

	final ring:Array<Point> = [];

	public function new() {
		super("alloc_small", "objects", N);
	}

	override public function setup() {
		for (i in 0...1024)
			ring.push(new Point(0, 0));
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var p = new Point(i, i ^ 0x55);
			ring[i & 1023] = p;
			sum = (sum + p.y) | 0;
		}
		for (p in ring)
			sum = (sum * 31 + p.x) | 0;
		return sum;
	}
}

/** Int-to-String conversion plus a concatenation per string. **/
class AllocStrings extends Benchmark {
	static inline var N = 6000000;

	final ring:Array<String> = [];

	public function new() {
		super("alloc_strings", "strings", N);
	}

	override public function setup() {
		for (i in 0...1024)
			ring.push("");
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var s = "k" + i;
			ring[i & 1023] = s;
			var last:Int = s.charCodeAt(s.length - 1);
			sum = (sum + s.length * 7 + last) | 0;
		}
		for (s in ring)
			sum = (sum * 31 + s.length) | 0;
		return sum;
	}
}

/** Arrays of 1 to 64 Ints grown by push, plus a 256 KB buffer every 4000 arrays. **/
class AllocArrays extends Benchmark {
	static inline var N = 1000000;

	final ring:Array<Array<Int>> = [];
	var big:Bytes;

	public function new() {
		super("alloc_arrays", "arrays", N);
	}

	override public function setup() {
		for (i in 0...256)
			ring.push([]);
		big = Bytes.alloc(1);
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var len = (i & 63) + 1;
			var a:Array<Int> = [];
			for (j in 0...len)
				a.push(i + j);
			ring[i & 255] = a;
			sum = (sum + a[len >> 1]) | 0;
			if (i % 4000 == 0) {
				big = Bytes.alloc(256 * 1024);
				big.set(i & 0x3ffff, i & 255);
				sum = (sum + big.get(i & 0x3ffff)) | 0;
			}
		}
		for (a in ring)
			sum = (sum * 31 + a.length) | 0;
		return sum;
	}
}

class LiveNode {
	public final id:Int;
	public final label:String;
	public var next:LiveNode;

	public function new(id:Int, next:LiveNode) {
		this.id = id;
		this.label = "n" + id;
		this.next = next;
	}
}

/**
	Collection pauses as the program sees them. A large live graph stays
	reachable while the program allocates in fixed work units, replacing
	one retained node in eight. Each unit's duration is recorded: the
	median is the normal cost of a unit, and the tail holds the units that
	included a collection. Stock hxcpp has no pause telemetry, so this
	measures both runtimes the same way, from outside the collector.
**/
class GcPauses extends Benchmark {
	static inline var LIVE = 300000;
	static inline var UNITS = 3000;
	static inline var PER_UNIT = 4000;

	final live:Array<LiveNode> = [];

	public function new() {
		super("gc_pauses", "objects", UNITS * PER_UNIT, true);
	}

	override public function setup() {
		var prev:LiveNode = null;
		for (i in 0...LIVE) {
			prev = new LiveNode(i, (i & 7) == 0 ? null : prev);
			live.push(prev);
		}
	}

	override public function run():Int {
		var rng = new Rng(0x1234567);
		var sum = 0;
		var nextId = LIVE;
		for (u in 0...UNITS) {
			var t0 = Timer.stamp();
			for (k in 0...PER_UNIT) {
				var p = new Point(k, u);
				sum = (sum + p.x) | 0;
				if ((k & 7) == 0) {
					var slot = rng.below(LIVE);
					live[slot] = new LiveNode(nextId++, null);
				}
			}
			latencies.push(Timer.stamp() - t0);
		}
		for (i in 0...64) {
			var n = live[i * 4099];
			sum = (sum * 31 + n.id + n.label.length) | 0;
		}
		return sum;
	}
}
