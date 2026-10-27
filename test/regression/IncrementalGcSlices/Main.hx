import cpp.vm.Gc;
#if HXCPP_GC_INCREMENTAL
import hxcpp.gc.Incremental;
#end

class Node {
	public var value:Int;
	public var next:Node;
	public function new(value:Int, next:Node = null) { this.value = value; this.next = next; }
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
	static var world:Array<Node>;
	static var root:Node;
	static var record:Dynamic;

	static function begin(holder:Dynamic) {
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(0,{0}.mPtr)", holder);
		for (_ in 0...10000) {
			Incremental.step(0.1);
			if (untyped __cpp__("__hxcpp_gc_incremental_test(1)")) {
				if (!Incremental.isActive()) throw "cycle finished before the mutation boundary";
				return;
			}
		}
		throw "holder was not scanned";
		#else
		Gc.run(true);
		#end
	}

	static function publish() {
		root.next = world[15000];
		world[15000] = null;
		Reflect.setField(record, "edge", new Node(999, root.next));
	}

	static function finish() {
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(4)");
		for (_ in 0...10000) if (!Incremental.step(0.1)) return;
		throw "incremental cycle did not finish";
		#else
		Gc.run(true);
		#end
	}

	static function main() {
		Gc.enable(false);
		world = [for (i in 0...20000) new Node(i, new Node(100000 + i))];
		root = new Node(-1);
		record = {edge: new Node(-2)};
		Gc.run(true);
		var retained = new Node(8);
		begin(root);
		#if HXCPP_GC_INCREMENTAL
		if (untyped __cpp__("__hxcpp_gc_incremental_test(8)") != 1) throw "partial collection discarded the allocation cursor";
		#end
		Sys.println("partial slices preserve the current allocation range: " + (retained.value == 8));
		untyped __cpp__("runJoined({0})", publish);
		finish();
		Sys.println("publication after holder scan preserves descendants: " + (root.next.value == 15000 && root.next.next.value == 115000));
		var field:Node = Reflect.field(record, "edge");
		Sys.println("detached writer and reflective stores preserve edges: " + (field.value == 999 && field.next == root.next));
		#if HXCPP_GC_INCREMENTAL
		var stats = Incremental.getStats();
		if (stats.cycles < 1 || stats.lastCycleSlices < 2) throw "collection was not split across pauses";
		#end
		Sys.println("collection can finish across separate marking slices: true");
		begin(root);
		Gc.run(false);
		#if HXCPP_GC_INCREMENTAL
		if (Incremental.isActive()) throw "explicit collection returned unfinished";
		untyped __cpp__("__hxcpp_gc_incremental_test(4)");
		#end
		Sys.println("explicit collection completes pending work: true");
		begin(root);
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(3)");
		#end
		Gc.run(true);
		var intact = true;
		for (i in 0...world.length) if (i != 15000 && (world[i].value != i || world[i].next.value != 100000 + i)) intact = false;
		Sys.println("fallback retraces objects left white by the partial cycle: " + intact);
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(4)");
		var invalid = 0;
		for (budget in [-1.0, Math.NaN, Math.POSITIVE_INFINITY, 1001.0]) {
			try { Incremental.step(budget); } catch (_:Dynamic) { invalid++; }
		}
		try { Incremental.configure(0); } catch (_:Dynamic) { invalid++; }
		try { Incremental.configure(0.5, -1); } catch (_:Dynamic) { invalid++; }
		if (invalid != 6 || Incremental.step(0) != Incremental.isActive()) throw "invalid scheduling request changed collection state";
		#end
		Sys.println("invalid scheduling requests leave the collector usable: true");
		Gc.enable(true);
	}
}
