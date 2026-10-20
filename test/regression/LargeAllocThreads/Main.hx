import sys.thread.Lock;
import sys.thread.Thread;

class Main {
	static function work(seed:Int):Bool {
		var ok = true;
		for (round in 0...200) {
			var bytes = haxe.io.Bytes.alloc(20000 + ((seed * 7919 + round * 104729) % 50000));
			bytes.set(bytes.length - 1, round & 0xff);
			var grown = new Array<Int>();
			for (i in 0...6000)
				grown.push(i);
			untyped __cpp__("::hx::GCChangeManagedMemory(4096, \"test\")");
			untyped __cpp__("::hx::GCChangeManagedMemory(-4096, \"test\")");
			if (bytes.get(bytes.length - 1) != (round & 0xff) || grown[5999] != 5999)
				ok = false;
		}
		return ok;
	}

	static function main() {
		var done = new Lock();
		var results = [for (i in 0...4) false];
		for (t in 0...4)
			Thread.create(() -> {
				results[t] = work(t);
				done.release();
			});
		for (t in 0...4)
			done.wait();
		Sys.println("large allocations on 4 threads: " + !results.contains(false));
	}
}
