import cpp.vm.Gc;

// The GC's large and managed memory count is a size_t. Releasing more managed
// memory than was reported wrapped it to near 2^64, after which every
// GCChangeManagedMemory call forced a collection, and negative GC tuning values
// became huge ones that stopped collections.
function main() {
	var big = haxe.io.Bytes.alloc(8 << 20);
	big.set(0, 1);
	untyped __cpp__("hx::GCChangeManagedMemory(-(256 << 20), \"test\")");
	Sys.println("count stays small after over-releasing: " + (Gc.memInfo64(Gc.MEM_INFO_LARGE) < 1024.0 * 1024 * 1024));
	big = null;
	Gc.run(true);
	Sys.println("and after a large object is freed: " + (Gc.memInfo64(Gc.MEM_INFO_LARGE) < 1024.0 * 1024 * 1024));
	untyped __cpp__("hx::GCReleaseManagedMemory(64 << 20)");
	Sys.println("and after GCReleaseManagedMemory: " + (Gc.memInfo64(Gc.MEM_INFO_LARGE) < 1024.0 * 1024 * 1024));

	Gc.setMinimumWorkingMemory(-1);
	Gc.setMinimumFreeSpace(-1);
	Gc.setTargetFreeSpacePercentage(-1);
	var keep:Array<Array<Int>> = [];
	for (i in 0...20000) {
		keep[i % 64] = [for (j in 0...1024) j];
	}
	Sys.println("negative tuning values still collect: " + (Gc.memInfo64(Gc.MEM_INFO_RESERVED) < 256.0 * 1024 * 1024));
}
