import sys.thread.Semaphore;

class Main {
	static function drop() {
		for (i in 0...100) {
			var s = new Semaphore(2);
			s.acquire();
		}
	}

	static function main() {
		drop();
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		Sys.println("collected");
		try {
			new Semaphore(-1);
			Sys.println("negative no throw");
		} catch (e:Dynamic) {
			Sys.println("negative threw");
		}
	}
}
