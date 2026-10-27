import sys.thread.Lock;

// A finite wait on an empty Lock ends when its timeout does. In a
// single-threaded Emscripten build it never returned (libhxcpp #339)
class Main {
	static function main() {
		var lock = new Lock();
		Sys.println('empty zero wait fails: ${!lock.wait(0)}');

		var start = haxe.Timer.stamp();
		var got = lock.wait(0.05);
		var waited = haxe.Timer.stamp() - start;
		Sys.stderr().writeString('waited $waited s\n');
		Sys.println('empty finite wait times out: ${!got && waited >= 0.04 && waited < 10}');

		lock.release();
		Sys.println('released finite wait succeeds: ${lock.wait(0.05)}');
		Sys.println('permit consumed: ${!lock.wait(0)}');
	}
}
