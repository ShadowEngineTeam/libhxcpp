import sys.thread.Lock;
import sys.thread.Thread;

// Dynamic boxes for -1 to 255 are made on first use and shared by every
// thread. The pointer was stored without ordering, so on weakly ordered CPUs a
// thread could find a box before it was built. Threads box every value at
// once from the start, and each box must hold its value and be the one box for
// it; TSan reports the race if it returns.
@:analyzer(ignore)
function boxed(i:Int):Dynamic {
	return i;
}

function main() {
	var threads = 4;
	var done = new Lock();
	var go = new Lock();
	var results = new sys.thread.Mutex();
	var wrong = 0;
	for (t in 0...threads) {
		Thread.create(() -> {
			go.wait();
			var bad = 0;
			for (round in 0...50)
				for (i in -1...256) {
					var d:Dynamic = boxed(i);
					if ((d : Int) != i || Std.string(d) != Std.string(i))
						bad++;
					if (!untyped __cpp__("({0}).mPtr == ({1}).mPtr", d, boxed(i)))
						bad++;
				}
			results.acquire();
			wrong += bad;
			results.release();
			done.release();
		});
	}
	for (t in 0...threads)
		go.release();
	for (t in 0...threads)
		done.wait();
	Sys.println('boxes: $wrong wrong');
}
