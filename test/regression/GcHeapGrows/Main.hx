import cpp.vm.Gc;

class P {
	public var x:Int;

	public function new(x) {
		this.x = x;
	}
}

// Churn with a tiny live set must let the heap grow to its working target
// (20 MB by default) instead of releasing every empty group whenever the
// allocator refilled its free list, which kept it near 5 MB and collected
// about four times as often (openfl/libhxcpp#230)
function main() {
	var ring = [for (i in 0...1024) new P(0)];
	var sum = 0;
	for (i in 0...20000000) {
		var p = new P(i);
		ring[i & 1023] = p;
		sum = (sum + p.x) | 0;
	}
	var reserved = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
	Sys.println(reserved >= 16 * 1048576 ? "grew" : 'stayed at ${Std.int(reserved / 1048576)} MB (sum $sum)');
}
