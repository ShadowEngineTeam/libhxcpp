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
// Dead large buffers that a collection keeps for reuse are still the
// process's memory, so the reserved figure counts them until they go.
class Main {
	static inline var MB = 1024 * 1024;

	static var anchor:Bytes;
	static var temporary:Array<Bytes>;

	static function populate() {
		temporary = [for (i in 0...16) Bytes.alloc(MB)];
		for (b in temporary)
			b.set(0, 1);
	}

	static function release() {
		temporary = null;
	}

	static var baseline:Float;
	static var moved:Float;

	// Reused buffers move from the cache to the live allocations
	static function reuse() {
		var reused = [for (i in 0...16) Bytes.alloc(MB)];
		moved = Gc.memInfo64(Gc.MEM_INFO_RESERVED) - baseline;
		reused[15].set(0, 1);
	}

	static function main() {
		anchor = Bytes.alloc(8 * MB);
		anchor.set(8 * MB - 1, 42);
		Gc.run(true);
		baseline = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
		untyped __cpp__("runJoined({0})", populate);
		untyped __cpp__("runJoined({0})", release);
		Gc.run(false);
		var cached = Gc.memInfo64(Gc.MEM_INFO_RESERVED) - baseline;
		Sys.println("reserved memory counts the recycle cache: " + (cached > 15 * MB));
		Sys.println("the cache is not counted as live: " + (Gc.memInfo64(Gc.MEM_INFO_LARGE) < 9 * MB));
		untyped __cpp__("runJoined({0})", reuse);
		Sys.println("reuse does not count a buffer twice: " + (moved > 15 * MB && moved < 17 * MB));
		Gc.compact();
		Sys.println("compaction releases the cache: " + (Gc.memInfo64(Gc.MEM_INFO_RESERVED) - baseline < MB));
		Sys.println("the anchor survives: " + (anchor.get(8 * MB - 1) == 42));
	}
}
