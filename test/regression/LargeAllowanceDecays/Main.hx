import cpp.vm.Gc;

class Main {
	static var hold:Array<haxe.io.Bytes> = [];

	static function main() {
		var done = new sys.thread.Lock();
		sys.thread.Thread.create(() -> {
			var big = haxe.io.Bytes.alloc(96 << 20);
			big.set(0, 1);
			big = null;
			done.release();
		});
		done.wait();
		Sys.sleep(0.2);
		Gc.run(true);

		var peak = 0.0;
		for (i in 0...1000) {
			hold[i % 8] = haxe.io.Bytes.alloc(512 * 1024);
			var large = Gc.memInfo64(Gc.MEM_INFO_LARGE);
			if (large > peak)
				peak = large;
		}
		Sys.println("garbage after a large allocation stays bounded: " + (peak < 150 * 1024 * 1024));
	}
}
