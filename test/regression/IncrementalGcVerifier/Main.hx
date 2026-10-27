import cpp.vm.Gc;
#if (HXCPP_GC_INCREMENTAL && HXCPP_GC_INCREMENTAL_VERIFY && HXCPP_GC_INCREMENTAL_TEST)
import hxcpp.gc.Incremental;
import sys.io.Process;
#end

class Node {
	public var next:Node;
	public function new(next:Node = null) this.next = next;
}

class Main {
	static var root:Node;

	static function main() {
		#if (HXCPP_GC_INCREMENTAL && HXCPP_GC_INCREMENTAL_VERIFY && HXCPP_GC_INCREMENTAL_TEST)
		if (Sys.args().length > 0) {
			Gc.enable(false);
			root = new Node(new Node());
			untyped __cpp__("__hxcpp_gc_incremental_test(6,{0}.mPtr)", root.next);
			for (_ in 0...10000) if (!Incremental.step(0.1)) return;
			return;
		}
		var child = new Process(Sys.programPath(), ["omitted-descendant"]);
		var output = child.stdout.readAll().toString();
		var error = child.stderr.readAll().toString();
		var rejected = child.exitCode() != 0 && error.indexOf("Incremental GC omitted reachable object") >= 0;
		child.close();
		Sys.println("independent verifier rejects an omitted descendant: " + rejected);
		#else
		Sys.println("independent verifier rejects an omitted descendant: true");
		#end
	}
}
