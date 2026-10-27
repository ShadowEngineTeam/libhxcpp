import cpp.vm.Gc;
#if HXCPP_GC_INCREMENTAL
import hxcpp.gc.Incremental;
#end

class Node {
	public var value:Int;
	public var next:Node;
	public function new(value:Int, next:Node = null) { this.value = value; this.next = next; }
}

class Main {
	static var root:Node;
	static var world:Array<Node>;
	static var record:Dynamic;

	static function main() {
		Gc.enable(false);
		root = new Node(1, new Node(2));
		world = [for (i in 0...20000) new Node(i)];
		Gc.run(true);
		#if HXCPP_GC_INCREMENTAL
		var finishing = false;
		for (_ in 0...10000) {
			if (!Incremental.step(0.1)) throw "no separate finishing boundary";
			if (untyped __cpp__("__hxcpp_gc_incremental_test(7)") == 1) {
				finishing = true;
				break;
			}
		}
		if (!finishing) throw "marking did not reach the finishing boundary";
		#end
		root.next = new Node(3, new Node(4));
		record = {edge: new Node(5, root.next)};
		world.push(new Node(6));
		#if HXCPP_GC_INCREMENTAL
		var done = false;
		for (_ in 0...10000) if (!Incremental.step(0.1)) { done = true; break; }
		if (!done) throw "finishing cycle did not complete";
		#else
		Gc.run(true);
		#end
		var edge:Node = record.edge;
		Sys.println("stores after the finishing boundary preserve new descendants: " + (root.next.value == 3 && root.next.next.value == 4 && edge.value == 5 && edge.next == root.next));
		Sys.println("container mutation before finishing remains visible: " + (world.length == 20001 && world[20000].value == 6));
		Gc.enable(true);
	}
}
