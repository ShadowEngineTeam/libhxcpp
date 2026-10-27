package;

import cpp.NativeArray;
import cpp.vm.Gc;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.BytesData;

/** Garbage large buffers, freed by a collection, so the allocator has a recycle cache to work with. **/
class LargeSeed {
	public static function seed(count:Int, size:Int) {
		drop(count, size);
		Gc.run(false);
	}

	static function drop(count:Int, size:Int) {
		var a = [for (i in 0...count) Bytes.alloc(size)];
		a[count - 1].set(0, 1);
	}
}

/**
	Exact resizes of one 4 KB buffer, made before 8192 other 4 KB buffers
	allocated since the last collection. Each resize releases the old
	buffer into the recycle cache.
**/
class LargeResize extends Benchmark {
	static inline var OTHERS = 8192;
	static inline var RESIZES = 20000;

	public function new() {
		super("large_resize", "resizes", RESIZES);
	}

	override public function setup() {
		LargeSeed.seed(64, 4096);
	}

	override public function run():Int {
		var target:BytesData = [];
		NativeArray.setSize(target, 4096);
		target[17] = 3;
		var others = [for (i in 0...OTHERS) Bytes.alloc(4096)];
		var sum = 0;
		for (i in 0...RESIZES) {
			NativeArray.setSize(target, (i & 1) == 0 ? 4100 : 4096);
			sum = (sum + target[17] + target.length) | 0;
		}
		return (sum + others.length) | 0;
	}
}

/**
	Allocation from a recycle cache holding 8192 buffers of an unrelated
	size: one buffer is resized between two sizes, each found in the cache.
**/
class LargeRecycle extends Benchmark {
	static inline var UNRELATED = 8192;
	static inline var RESIZES = 20000;

	public function new() {
		super("large_recycle", "resizes", RESIZES);
	}

	override public function setup() {
		LargeSeed.seed(UNRELATED + 64, 4100);
	}

	override public function run():Int {
		// Released at once, so they wait in the cache
		var unrelated:Array<BytesData> = [];
		for (i in 0...UNRELATED) {
			var d:BytesData = [];
			NativeArray.setSize(d, 4100);
			unrelated.push(d);
		}
		for (d in unrelated)
			NativeArray.setSize(d, 0);
		var target:BytesData = [];
		NativeArray.setSize(target, 4096);
		target[5] = 7;
		var sum = 0;
		for (i in 0...RESIZES) {
			NativeArray.setSize(target, (i & 1) == 0 ? 4104 : 4096);
			sum = (sum + target[5] + target.length) | 0;
		}
		return sum;
	}
}

/**
	Copies of a 1 MB buffer: Bytes.sub, Array.copy and an ASCII string
	read with getString. Each fills every byte of a new large allocation,
	mostly one recycled from the copies before it.
**/
class LargeCopy extends Benchmark {
	static inline var SIZE = 1 << 20;
	static inline var COPIES = 128;

	var source:Bytes;

	public function new() {
		super("large_copy", "copies", COPIES * 3);
	}

	override public function setup() {
		source = Bytes.alloc(SIZE);
		for (i in 0...SIZE)
			source.set(i, 65 + i % 26);
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...COPIES) {
			var sub = source.sub(i & 63, SIZE - 64);
			var copy = source.getData().copy();
			var text = source.getString(i & 63, SIZE - 64);
			sum = (sum + sub.get(SIZE - 65) + copy[SIZE - 1] + text.length + StringTools.fastCodeAt(text, 100)) | 0;
		}
		return sum;
	}
}

/**
	The collection after a burst of 4 KB garbage buffers went into the
	recycle cache. Each work unit is that collection alone, which drops
	the cache, while a 128 MB buffer stays live.
**/
class LargeCachePurge extends Benchmark {
	static inline var ROUNDS = 8;
	static inline var BUFFERS = 16384;

	var anchor:Bytes;

	public function new() {
		super("large_cache_purge", "collections", ROUNDS, true);
	}

	override public function setup() {
		anchor = Bytes.alloc(128 << 20);
		anchor.set(12345, 9);
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...ROUNDS) {
			LargeSeed.seed(BUFFERS, 4096);
			var t0 = Timer.stamp();
			Gc.run(false);
			latencies.push(Timer.stamp() - t0);
			sum = (sum + anchor.get(12345)) | 0;
		}
		return sum;
	}
}
