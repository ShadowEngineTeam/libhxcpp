// On Emscripten gettimeofday reads Date.now(), which the program can move, as a
// clock correction would; elsewhere the clock is left alone and the program
// checks only that the stamps go forward
@:cppFileCode('
#ifdef EMSCRIPTEN
#include <emscripten.h>
EM_JS(void, adjustClock, (double offset), {
	const original = Date.now;
	globalThis.restoreClock = function() { Date.now = original; };
	Date.now = function() { return original() + offset; };
});
EM_JS(void, restoreClock, (), { globalThis.restoreClock(); });
#else
static void adjustClock(double) {}
static void restoreClock() {}
#endif
')
class Main {
	static function gcStamp():Float {
		return untyped __global__.__hxcpp_time_stamp();
	}

	static function plausible(elapsed:Float):Bool {
		return elapsed >= 0 && elapsed < 10;
	}

	// The collector's elapsed-time stamps followed the wall clock where
	// gettimeofday was available, so a correction made its pause times and the
	// heap sizing's collection ratios negative or a minute long
	static function main() {
		var start = gcStamp();
		untyped __cpp__("adjustClock(-60000.0)");
		var elapsed = gcStamp() - start;
		untyped __cpp__("restoreClock()");
		Sys.println("GC stamps ignore a backward clock change: " + plausible(elapsed));

		start = gcStamp();
		untyped __cpp__("adjustClock(60000.0)");
		elapsed = gcStamp() - start;
		untyped __cpp__("restoreClock()");
		Sys.println("GC stamps ignore a forward clock change: " + plausible(elapsed));

		var timerStart = haxe.Timer.stamp();
		untyped __cpp__("adjustClock(-60000.0)");
		var timerElapsed = haxe.Timer.stamp() - timerStart;
		untyped __cpp__("restoreClock()");
		Sys.println("Timer.stamp ignores a backward clock change: " + plausible(timerElapsed));
	}
}
