// Timers fire after main returns, from the event loop, which waits on a Lock
// until the next one is due. In a single-threaded Emscripten build that wait
// never returned, so no timer fired (libhxcpp #339)
class Main {
	static function main() {
		var start = haxe.Timer.stamp();
		haxe.Timer.delay(function() {
			var elapsed = haxe.Timer.stamp() - start;
			Sys.stderr().writeString('second timer after $elapsed s\n');
			Sys.println('second timer fired: ${elapsed >= 0.025}');
		}, 30);
		haxe.Timer.delay(function() Sys.println("first timer fired: true"), 10);
		Sys.println("timers scheduled: true");
	}
}
