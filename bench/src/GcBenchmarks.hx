package;

import haxe.Timer;
import haxe.ds.WeakMap;

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
