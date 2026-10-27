import cpp.vm.Gc;
#if HXCPP_GC_INCREMENTAL
import hxcpp.gc.Incremental;
#end

class Node {
	public var value:Int;
	public function new(value:Int) this.value = value;
}

class Main {
	static var values:Array<Node>;
	static var expected:Array<Int>;

	static function main() {
		Gc.enable(false);
		values = [for (i in 0...32768) new Node(i)];
		expected = [for (i in 0...32768) i];
		Gc.run(true);
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(0, nullptr)");
		var partial = false;
		for (_ in 0...10000) {
			Incremental.step(0.1);
			if (untyped __cpp__("__hxcpp_gc_incremental_test(5,{0}.mPtr)", values)) {
				partial = true;
				break;
			}
		}
		if (!partial || !Incremental.isActive()) throw "array was not partially scanned";
		#end
		values.splice(0, 2048);
		expected.splice(0, 2048);
		values.reverse(); expected.reverse();
		for (i in 0...32768) {
			values.push(new Node(50000 + i));
			expected.push(50000 + i);
		}
		#if HXCPP_GC_INCREMENTAL
		untyped __cpp__("__hxcpp_gc_incremental_test(4)");
		var unfinished = true;
		for (_ in 0...10000) {
			unfinished = Incremental.step(0.1);
			if (!unfinished) break;
		}
		if (unfinished) throw "resized array cycle did not finish";
		#else
		Gc.run(true);
		#end
		var valid = values.length == expected.length;
		for (i in 0...expected.length) if (values[i] == null || values[i].value != expected[i]) valid = false;
		Sys.println("resized and reordered range jobs preserve every payload: " + valid);
		Gc.compact();
		Sys.println("compaction preserves completed range results: " + (values[0].value == expected[0] && values[values.length - 1].value == expected[expected.length - 1]));
		Gc.enable(true);
	}
}
