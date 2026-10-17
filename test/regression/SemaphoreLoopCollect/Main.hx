import sys.thread.Lock;
import sys.thread.Semaphore;
import sys.thread.Thread;

// Semaphore.acquire returned at once when the semaphore was free, without
// checking for a pending collection. A thread looping acquire and release
// allocates nothing and so never reached a safe point, and a collection on
// another thread waited for it until the loop ended. The worker stops on the
// clock, since polling a Lock would itself reach a safe point.
function main() {
	var started = new Lock();
	var finished = new Lock();
	var seconds = 3.0;
	Thread.create(() -> {
		var semaphore = new Semaphore(1);
		var deadline = Sys.time() + seconds;
		started.release();
		while (Sys.time() < deadline) {
			semaphore.acquire();
			semaphore.release();
		}
		finished.release();
	});
	started.wait();
	var t0 = haxe.Timer.stamp();
	cpp.vm.Gc.run(true);
	var waited = haxe.Timer.stamp() - t0;
	finished.wait();
	Sys.println(waited < seconds / 2 ? "collection did not wait for the loop" : 'collection waited ${Std.int(waited * 1000)} ms for the loop');
}
