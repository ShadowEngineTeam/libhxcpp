import cpp.vm.Gc;

class Small {
	public var a:Int;

	public function new(a:Int)
		this.a = a;
}

// Gc.memInfo64(4), MEM_INFO_LIVE, reports the bytes of the objects that
// survived the last full collection, where MEM_INFO_USAGE counts every
// 128-byte line a live object touches.
function main() {
	var keep = [];
	for (i in 0...800000) {
		var s = new Small(i);
		if (i % 16 == 0)
			keep.push(s);
	}
	Gc.run(true);
	var live = Gc.memInfo64(4);
	var usage = Gc.memInfo64(Gc.MEM_INFO_USAGE);
	Sys.println("live bytes reported: " + (live > 0));
	Sys.println("live bytes within line usage: " + (live <= usage));
	Sys.println("scattered survivors use more lines than bytes: " + (live < usage * 0.75));
	Sys.println("kept " + keep.length);
}
