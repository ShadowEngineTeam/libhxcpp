import sys.thread.Lock;
import sys.thread.Thread;

// Timer.stamp counts from its first call. That start was checked for zero, so
// threads making the first call together could each set it and move later
// stamps backwards. Threads make the first call at once here, before anything
// else has called it, and each checks that its stamps never go backwards.
function main() {
	var threads = 4;
	var go = new Lock();
	var done = new Lock();
	var mutex = new sys.thread.Mutex();
	var backwards = 0;
	for (t in 0...threads) {
		Thread.create(() -> {
			go.wait();
			var last = haxe.Timer.stamp();
			var bad = 0;
			for (i in 0...100000) {
				var now = haxe.Timer.stamp();
				if (now < last || Math.isNaN(now) || !Math.isFinite(now))
					bad++;
				last = now;
			}
			mutex.acquire();
			backwards += bad;
			mutex.release();
			done.release();
		});
	}
	for (t in 0...threads)
		go.release();
	for (t in 0...threads)
		done.wait();
	Sys.println('stamps that went backwards: $backwards');
}
