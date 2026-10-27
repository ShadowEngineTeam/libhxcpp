package;

import haxe.Timer;
import haxe.ds.WeakMap;
import haxe.io.Bytes;
import sys.thread.Lock;
import sys.thread.Thread;

class GcKey {
	public var id:Int;

	public function new(id:Int)
		this.id = id;
}

/**
	Collections of a heap whose large part does not change between them, as a
	program with long-lived tables sees. Each run() requests COLLECTIONS
	collections, which are minor ones with HXCPP_GC_GENERATIONAL and full ones
	otherwise, and records each one's duration.
**/
class GcCollections extends Benchmark {
	static inline var COLLECTIONS = 20;

	public function new(name:String) {
		super(name, "collections", COLLECTIONS, true);
	}

	override public function run():Int {
		return collect();
	}

	function collect():Int {
		for (i in 0...COLLECTIONS) {
			var t0 = Timer.stamp();
			cpp.vm.Gc.run(false);
			latencies.push(Timer.stamp() - t0);
		}
		return check();
	}

	function check():Int {
		return 0;
	}

	// Garbage that leaves free blocks behind, so that a generational build
	//  collects in minor collections instead of falling back to full ones
	function spare(inCount:Int) {
		var garbage = [for (i in 0...inCount) new GcKey(i)];
		if (garbage.length != inCount)
			throw "spare";
	}
}

/** An unchanged WeakMap of 262,144 retained keys to Int values (libhxcpp #333). **/
class GcWeakMapInt extends GcCollections {
	static inline var N = 262144;

	final keys:Array<GcKey> = [];
	final map = new WeakMap<GcKey, Int>();

	public function new() {
		super("gc_weak_map_int");
	}

	override public function setup() {
		for (i in 0...N) {
			var key = new GcKey(i);
			keys.push(key);
			map.set(key, i * 3);
		}
		spare(N * 4);
	}

	override function check():Int {
		var sum = 0;
		for (i in 0...64) {
			var v:Int = map.get(keys[i * 4093]);
			sum = (sum * 31 + v) | 0;
		}
		return sum;
	}
}

/** 250,000 retained objects, each given an ID with __hxcpp_obj_id (libhxcpp #357). **/
class GcObjectIds extends GcCollections {
	static inline var N = 250000;

	final objects:Array<GcKey> = [];
	final ids:Array<Int> = [];

	public function new() {
		super("gc_object_ids");
	}

	override public function setup() {
		for (i in 0...N) {
			var o = new GcKey(i);
			objects.push(o);
			ids.push(untyped __global__.__hxcpp_obj_id(o));
		}
		spare(N * 4);
	}

	override function check():Int {
		var sum = 0;
		for (i in 0...64) {
			var o = objects[i * 3907];
			sum = (sum * 31 + o.id + (untyped __global__.__hxcpp_obj_id(o) == ids[i * 3907] ? 1 : 0)) | 0;
		}
		return sum;
	}
}

/** 250,000 retained objects, each given to Gc.doNotKill (libhxcpp #383). **/
class GcZombieReservations extends GcCollections {
	static inline var N = 250000;

	final objects:Array<GcKey> = [];

	public function new() {
		super("gc_zombie_reservations");
	}

	override public function setup() {
		for (i in 0...N) {
			var o = new GcKey(i);
			objects.push(o);
			cpp.vm.Gc.doNotKill(o);
		}
		spare(N * 4);
	}

	override function check():Int {
		var sum = cpp.vm.Gc.getNextZombie() == null ? 0 : 1;
		for (i in 0...64)
			sum = (sum * 31 + objects[i * 3907].id) | 0;
		return sum;
	}
}

/**
	125,000 retained objects given finalizers again before each full
	collection, which moves the registrations to the old table (libhxcpp #375).
	Each latency is that collection; no finalizer runs.
**/
class GcFinalizerPromotion extends Benchmark {
	static inline var N = 125000;
	static inline var ROUNDS = 4;
	static var finalized = 0;

	final objects:Array<GcKey> = [];

	public function new() {
		super("gc_finalizer_promotion", "collections", ROUNDS, true);
	}

	static function finalize(o:GcKey):Void {
		finalized++;
	}

	override public function setup() {
		for (i in 0...N)
			objects.push(new GcKey(i));
	}

	override public function run():Int {
		for (r in 0...ROUNDS) {
			for (o in objects)
				cpp.vm.Gc.setFinalizer(o, cpp.Callable.fromStaticFunction(finalize));
			var t0 = Timer.stamp();
			cpp.vm.Gc.run(true);
			latencies.push(Timer.stamp() - t0);
		}
		return finalized + objects[N - 1].id;
	}
}

/**
	65,536 retained 4 KB buffers, with twelve raw pointers into them on the stack
	while the collections run, so the stack scan looks them up (libhxcpp #365).
**/
@:cppFileCode('
static int bench_with_stack_pointers(::Array< ::Array< unsigned char > > inPool, ::Dynamic inRun) {
	volatile void *ptrs[12];
	int n = inPool->length;
	for (int i = 0; i < 12; i++)
		ptrs[i] = inPool[i * (n / 12)]->GetBase();
	int result = inRun();
	for (int i = 0; i < 12; i++)
		if (!ptrs[i])
			result++;
	return result;
}
')
class GcLargeStackRoots extends GcCollections {
	static inline var N = 65536;

	final pool:Array<haxe.io.BytesData> = [];

	public function new() {
		super("gc_large_stack_roots");
	}

	override public function setup() {
		for (i in 0...N) {
			var b = Bytes.alloc(4096);
			b.set(0, i & 255);
			pool.push(b.getData());
		}
		spare(N * 4);
	}

	override public function run():Int {
		return untyped __cpp__("bench_with_stack_pointers({0}, {1})", pool, collect);
	}

	override function check():Int {
		var sum = 0;
		for (i in 0...64) {
			sum = (sum * 31 + pool[i * 1021][0]) | 0;
		}
		return sum;
	}
}

/**
	A collection that another thread asks for 5 ms into a long regular
	expression match on this one, over a 32 MB subject (libhxcpp #330). Each
	latency is how long that request took, the match itself is the work unit.
**/
class GcRegexWait extends Benchmark {
	static inline var MATCHES = 4;

	var subject:String;
	final re = ~/^[a-z]+$/;
	final start = new Lock();
	final done = new Lock();
	var requestTime = 0.0;

	public function new() {
		super("gc_regex_wait", "matches", MATCHES, true);
	}

	override public function setup() {
		var b = Bytes.alloc(32 * 1024 * 1024);
		b.fill(0, b.length, 97);
		subject = b.toString();
		Thread.create(() -> {
			while (true) {
				start.wait();
				Sys.sleep(0.005);
				var t0 = Timer.stamp();
				cpp.vm.Gc.run(true);
				requestTime = Timer.stamp() - t0;
				done.release();
			}
		});
	}

	override public function run():Int {
		var matched = 0;
		for (i in 0...MATCHES) {
			start.release();
			if (re.match(subject))
				matched += re.matchedPos().len;
			done.wait();
			latencies.push(requestTime);
		}
		return matched;
	}
}
