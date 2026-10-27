import haxe.ds.WeakMap;

class Item {
	public var value:Int;

	public function new(value:Int)
		this.value = value;
}

class Holder {
	public var key:Item;

	public function new(key:Item)
		this.key = key;
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
	std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
')
class Main {
	static inline var COUNT = 1000;

	static var keys:Array<Item>;
	static var ints:WeakMap<Item, Int>;
	static var floats:WeakMap<Item, Float>;
	static var int64s:WeakMap<Item, haxe.Int64>;
	static var dynamics:WeakMap<Item, Dynamic>;
	static var strings:WeakMap<Item, String>;
	static var transient:WeakMap<Item, Int>;
	static var cycles:WeakMap<Item, Dynamic>;
	static var correct:Bool;
	// A value freed in error can still read correctly until its memory is
	// reused, so the object values are also watched through weak references
	static var watched:Array<cpp.vm.WeakRef<Item>>;

	static function populate():Void {
		keys = [for (i in 0...COUNT) new Item(i)];
		ints = new WeakMap();
		floats = new WeakMap();
		int64s = new WeakMap();
		dynamics = new WeakMap();
		strings = new WeakMap();
		for (key in keys) {
			ints.set(key, key.value * 3);
			floats.set(key, key.value + 0.5);
			int64s.set(key, haxe.Int64.make(key.value, 7));
			dynamics.set(key, key.value);
		}
	}

	// Young values through old live keys, stored after the maps went old. The
	// Int map of Dynamics converts to object storage on the first object value
	static function storeYoung():Void {
		watched = [];
		for (i in 0...COUNT) {
			if (i % 2 == 0) {
				var value = new Item(i + 10000);
				dynamics.set(keys[i], value);
				watched.push(new cpp.vm.WeakRef(value));
			}
			strings.set(keys[i], "young " + i);
		}
		transient = new WeakMap();
		cycles = new WeakMap();
		for (i in 0...COUNT) {
			transient.set(new Item(i), i);
			var key = new Item(i);
			cycles.set(key, new Holder(key));
		}
	}

	// Reuses the memory of anything freed
	static function churn():Void {
		var keep = 0;
		for (i in 0...COUNT * 20)
			keep += ("other " + i).length + new Item(i).value;
	}

	static function verifyValues():Void {
		correct = true;
		for (ref in watched)
			if (ref.get() == null)
				correct = false;
		for (i in 0...COUNT) {
			var key = keys[i];
			if (key.value != i || ints.get(key) != i * 3 || floats.get(key) != i + 0.5)
				correct = false;
			var big = int64s.get(key);
			if (big.high != i || big.low != 7)
				correct = false;
			var dyn:Dynamic = dynamics.get(key);
			if (i % 2 == 0 ? (dyn.value != i + 10000) : (dyn != i))
				correct = false;
			if (strings.get(key) != "young " + i)
				correct = false;
		}
	}

	static function count(map:WeakMap<Item, Dynamic>):Int {
		var n = 0;
		for (key in map.keys())
			n++;
		return n;
	}

	static var transientLeft:Int;
	static var cyclesLeft:Int;

	static function countDead():Void {
		transientLeft = count(cast transient);
		cyclesLeft = count(cycles);
	}

	// Weak maps with Int, Float or Int64 values skip the ephemeron value scan,
	// since those values hold nothing to mark. A map that converts to object or
	// String storage must still mark its values through live keys, and a value
	// that leads back to its own key must not keep it
	static function main() {
		untyped __cpp__("runJoined({0})", populate);
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		untyped __cpp__("runJoined({0})", storeYoung);
		for (i in 0...8)
			cpp.vm.Gc.run(false);
		untyped __cpp__("runJoined({0})", churn);
		untyped __cpp__("runJoined({0})", verifyValues);
		Sys.println("values survive minor collections: " + correct);
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		untyped __cpp__("runJoined({0})", churn);
		untyped __cpp__("runJoined({0})", verifyValues);
		Sys.println("values survive full collections: " + correct);
		untyped __cpp__("runJoined({0})", countDead);
		// A conservative stack scan can keep one or two
		Sys.println("transient keys are removed: " + (transientLeft < 8));
		Sys.println("value-to-key cycles are collected: " + (cyclesLeft < 8));
	}
}
