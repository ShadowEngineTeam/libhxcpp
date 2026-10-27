class CensusItem {
	public var value:Int;

	public function new(value:Int)
		this.value = value;
}

@:cppFileCode('
#include <thread>
#include <atomic>
#include <hx/Native.h>
static std::atomic<int> sStarted(0);
static std::atomic<int> sWrong(0);
static void runJoined(Dynamic callback) {
	std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
// Two workers that make their requests together, each starting when both are attached
static void runTogether(Dynamic callback) {
	auto body = [callback]() mutable {
		hx::NativeAttach attach;
		{
			hx::AutoGCFreeZone freeZone;
			sStarted++;
			while (sStarted.load() < 2)
				std::this_thread::yield();
		}
		callback();
	};
	std::thread a(body), b(body);
	hx::AutoGCFreeZone freeZone;
	a.join();
	b.join();
}
')
class Main {
	static inline var COUNT = 50000;

	static var items:Array<CensusItem>;
	static var intact:Bool;

	static function populate():Void {
		items = [for (i in 0...COUNT) new CensusItem(i)];
	}

	static function census():Void {
		for (request in 0...8) {
			var counted = 0;
			var rows:Array<Dynamic> = untyped __global__.__hxcpp_gc_census();
			for (row in rows)
				if (row.name == "CensusItem")
					counted = row.count;
			if (counted != COUNT)
				untyped __cpp__("sWrong++");
		}
	}

	static function verify():Void {
		intact = items.length == COUNT;
		for (i in 0...items.length)
			if (items[i].value != i)
				intact = false;
	}

	// A census request published its counting buffers through globals that another
	// request replaced or cleared, and a request that found another collection
	// running returned without its own, so it could count no instances at all
	static function main() {
		untyped __cpp__("runJoined({0})", populate);
		if (Sys.args()[0] == "serial") {
			untyped __cpp__("runJoined({0})", census);
			untyped __cpp__("runJoined({0})", census);
		} else
			untyped __cpp__("runTogether({0})", census);
		untyped __cpp__("runJoined({0})", verify);
		Sys.println("each census counts the retained class: " + untyped __cpp__("(sWrong.load()==0)"));
		Sys.println("retained objects remain intact: " + intact);
	}
}
