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
// Old large buffers can only be freed by a full collection. Collections
// that large allocations start must reach one, even when the small heap is
// nearly empty, or the released old buffers stay until something asks.
class Main {
	static inline var MB = 1024 * 1024;

	static var held:Array<Bytes>;
	static var baseline:Float;
	static var retained:Float;
	static var drops = 0;

	static function populate() {
		held = [for (i in 0...64) {
			var b = Bytes.alloc(MB);
			b.set(0, i);
			b;
		}];
	}

	static function release() {
		held = null;
	}

	static function churn() {
		var previous = Gc.memInfo64(Gc.MEM_INFO_LARGE);
		for (i in 0...256) {
			var b = Bytes.alloc(MB);
			b.set(0, i % 251);
			var current = Gc.memInfo64(Gc.MEM_INFO_LARGE);
			if (current < previous)
				drops++;
			previous = current;
		}
		retained = Gc.memInfo64(Gc.MEM_INFO_LARGE) - baseline;
	}

	static function main() {
		Gc.run(true);
		baseline = Gc.memInfo64(Gc.MEM_INFO_LARGE);
		untyped __cpp__("runJoined({0})", populate);
		Gc.run(true);
		untyped __cpp__("runJoined({0})", release);
		untyped __cpp__("runJoined({0})", churn);
		Sys.println("large allocation pressure starts collections: " + (drops > 0));
		Sys.println("large pressure reclaims released old buffers: " + (retained < 48 * MB));
		Gc.run(true);
		Sys.println("a full collection releases the rest: " + (Gc.memInfo64(Gc.MEM_INFO_LARGE) - baseline < MB));
	}
}
