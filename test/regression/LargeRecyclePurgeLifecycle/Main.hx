import cpp.vm.Gc;
import haxe.io.Bytes;

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
// Each collection drops the recycle cache it finds, and the buffers are
// freed after the threads run again. Buffers reused from the cache before
// that must be whole, new ones zero-filled, and compaction must still give
// everything back before it returns.
class Main {
	static inline var MB = 1024 * 1024;

	static var anchor:Bytes;
	static var burst:Array<Bytes>;
	static var zeroed = true;

	static function makeBurst() {
		burst = [for (i in 0...4096) Bytes.alloc(4096 + 4 * (i % 7))];
		for (b in burst)
			b.fill(0, b.length, 0x5a);
	}

	static function dropBurst() {
		burst = null;
	}

	static function reuse() {
		var kept = [];
		for (i in 0...2048) {
			var b = Bytes.alloc(4096 + 4 * (i % 11));
			for (j in 0...b.length)
				if (b.get(j) != 0) {
					zeroed = false;
					break;
				}
			b.fill(0, b.length, i & 255);
			kept.push(b);
		}
		for (i in 0...kept.length)
			if (kept[i].get(0) != i & 255 || kept[i].get(kept[i].length - 1) != i & 255)
				zeroed = false;
	}

	static function anchorIntact():Bool {
		for (i in 0...1024)
			if (anchor.get(i * 1024) != i % 251)
				return false;
		return true;
	}

	static function main() {
		anchor = Bytes.alloc(MB);
		for (i in 0...1024)
			anchor.set(i * 1024, i % 251);
		Gc.run(true);
		var baseline = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
		for (round in 0...8) {
			untyped __cpp__("runJoined({0})", makeBurst);
			untyped __cpp__("runJoined({0})", dropBurst);
			// Caches the burst, then reuses part of it
			Gc.run(false);
			untyped __cpp__("runJoined({0})", reuse);
			// Drops what is left of the cache, and caches the reused buffers
			Gc.run(false);
			untyped __cpp__("runJoined({0})", reuse);
			Gc.run(false);
		}
		Sys.println("reused and new large buffers are whole and zero-filled: " + zeroed);
		Sys.println("the retained buffer survives the purges: " + anchorIntact());
		Gc.compact();
		Sys.println("compaction gives back the dropped caches: " + (Gc.memInfo64(Gc.MEM_INFO_RESERVED) - baseline < MB));
		Sys.println("the retained buffer survives compaction: " + anchorIntact());
	}
}
