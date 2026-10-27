class Item {
	public var value:Int;

	public function new(value:Int)
		this.value = value;
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
	std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
// Without the moving collector a 32-bit build gives the address of an object as
// its ID, as __hxcpp_obj_id in Immix.cpp does, with no table to clear
static bool idsAreAddresses() {
#if defined(HXCPP_M64) || defined(HXCPP_GC_MOVING)
	return false;
#else
	return true;
#endif
}
')
class Main {
	static inline var COUNT = 2000;

	static var old:Array<Item>;
	static var oldIds:Array<Int>;
	static var young:Array<Item>;
	static var youngIds:Array<Int>;
	static var deadIds:Array<Int>;
	static var correct:Bool;
	static var left:Int;

	static function id(item:Item):Int {
		return untyped __global__.__hxcpp_obj_id(item);
	}

	static function lookup(id:Int):Item {
		return untyped __global__.__hxcpp_id_obj(id);
	}

	static function populateOld():Void {
		old = [for (i in 0...COUNT) new Item(i)];
		oldIds = [for (item in old) id(item)];
	}

	static function populateYoung():Void {
		young = [for (i in 0...COUNT) new Item(COUNT + i)];
		youngIds = [for (item in young) id(item)];
		deadIds = [for (i in 0...COUNT) id(new Item(-1))];
	}

	static function same(items:Array<Item>, ids:Array<Int>):Bool {
		for (i in 0...items.length)
			if (id(items[i]) != ids[i] || lookup(ids[i]) != items[i])
				return false;
		return true;
	}

	static function cleared(ids:Array<Int>):Int {
		// A dead object's address stays its ID there, and looking it up would
		// read freed memory, so only the live IDs can be checked
		if (untyped __cpp__("idsAreAddresses()"))
			return 0;
		var n = 0;
		for (i in ids)
			if (lookup(i) != null)
				n++;
		return n;
	}

	static function verifyLive():Void {
		correct = same(old, oldIds) && same(young, youngIds);
		for (i in 0...COUNT)
			if (old[i].value != i || young[i].value != COUNT + i)
				correct = false;
		left = cleared(deadIds);
	}

	static function releaseOld():Void {
		old = null;
	}

	static function verifyReleased():Void {
		left = cleared(oldIds);
		// Freed IDs go to new objects, which look up as themselves
		var fresh = [for (i in 0...COUNT) new Item(i)];
		var freshIds = [for (item in fresh) id(item)];
		correct = same(fresh, freshIds) && same(young, youngIds);
	}

	// A minor collection checks only the IDs given since the last collection,
	// as the old objects cannot die in it; a full one checks them all. Either
	// way a live object keeps its ID and a dead one's lookup is cleared before
	// the ID is given again
	static function main() {
		untyped __cpp__("runJoined({0})", populateOld);
		cpp.vm.Gc.run(true);
		untyped __cpp__("runJoined({0})", populateYoung);
		for (i in 0...4)
			cpp.vm.Gc.run(false);
		untyped __cpp__("runJoined({0})", verifyLive);
		// A conservative stack scan can keep one or two
		Sys.println("minor collections keep live IDs: " + correct);
		Sys.println("minor collections clear dead young IDs: " + (left < 8));
		cpp.vm.Gc.run(true);
		untyped __cpp__("runJoined({0})", verifyLive);
		Sys.println("full collection keeps live IDs: " + correct);
		untyped __cpp__("runJoined({0})", releaseOld);
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		untyped __cpp__("runJoined({0})", verifyReleased);
		Sys.println("full collection clears released old IDs: " + (left < 8));
		Sys.println("freed IDs are given again correctly: " + correct);
	}
}
