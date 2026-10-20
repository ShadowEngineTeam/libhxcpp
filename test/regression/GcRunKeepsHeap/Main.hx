import cpp.vm.Gc;

class P {
	public var x:Int;

	public function new(x) {
		this.x = x;
	}
}

// Gc.run(true) must collect without giving the grown heap back to the system.
// It used to release every empty group like Gc.compact(), so the next work had
// to commit and fault the whole heap in again, which made map and allocation
// benchmarks up to 2x slower than stock hxcpp (openfl/libhxcpp#231, #233).
// Gc.compact() still releases; GcReleaseEmptyBlocks checks that.
function main() {
	var ring = [for (i in 0...1024) new P(0)];
	var sum = 0;
	for (i in 0...20000000) {
		var p = new P(i);
		ring[i & 1023] = p;
		sum = (sum + p.x) | 0;
	}
	var before = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
	Gc.run(true);
	var after = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
	Sys.println(after >= 16 * 1048576 && after >= before / 2 ? "kept" : 'released to ${Std.int(after / 1048576)} of ${Std.int(before / 1048576)} MB (sum $sum)');
}
