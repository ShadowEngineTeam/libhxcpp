import sys.thread.Semaphore;

// Permits that are already there need no other thread, so single-threaded
// Emscripten builds take and give them too (libhxcpp #334)
class Main {
	static function check(claim:String, f:() -> Bool) {
		var result = try f() catch (e:Dynamic) {
			Sys.stderr().writeString('$claim threw $e\n');
			false;
		}
		Sys.println('$claim: $result');
	}

	static function main() {
		check("initial permits taken", () -> {
			var s = new Semaphore(2);
			s.tryAcquire() && s.tryAcquire() && !s.tryAcquire();
		});
		check("empty zero timeout fails", () -> !new Semaphore(0).tryAcquire(0));
		check("release gives a permit", () -> {
			var s = new Semaphore(0);
			s.release();
			s.tryAcquire() && !s.tryAcquire();
		});
		check("acquire takes a permit", () -> {
			var s = new Semaphore(1);
			s.acquire();
			!s.tryAcquire();
		});
		check("empty timed wait times out", () -> {
			var s = new Semaphore(0);
			var start = haxe.Timer.stamp();
			var got = s.tryAcquire(0.05);
			var waited = haxe.Timer.stamp() - start;
			Sys.stderr().writeString('waited $waited s\n');
			!got && waited >= 0.04 && waited < 10;
		});
	}
}
