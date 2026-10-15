import cpp.vm.Gc;
import sys.thread.Lock;
import sys.thread.Thread;

// The garbage is made on a thread that then exits, so no stale stack slot
// (common on 32-bit builds) keeps it alive through conservative scanning
function churn() {
	var done = new Lock();
	Thread.create(() -> {
		var keep = [];
		for (i in 0...300000)
			keep.push([for (j in 0...16) j]);
		done.release();
	});
	done.wait();
	Sys.sleep(0.1);
}

function main() {
	churn();
	var peak = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
	Gc.compact();
	var after = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
	Sys.println(after < peak / 2 ? "released" : 'kept ${Std.int(after / 1048576)} of ${Std.int(peak / 1048576)} MB');
}
