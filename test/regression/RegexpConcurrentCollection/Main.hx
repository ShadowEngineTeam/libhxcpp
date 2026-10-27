import haxe.atomic.AtomicBool;
import sys.thread.Thread;

class Main {
	// Both threads use these, so they are atomic
	static var stop = new AtomicBool(false);
	static var collecting = new AtomicBool(false);

	static function subject(prefix:String, n:Int, round:Int):String {
		var buf = new StringBuf();
		buf.add(prefix);
		for (i in 0...n)
			buf.addChar(97 + (i + round) % 3);
		buf.add("xbbbccc");
		return buf.toString();
	}

	// Each round makes a new subject and expression, so either can be in a block
	// that a compaction would move while the match runs beside it
	static function check(prefix:String, n:Int, rounds:Int):Bool {
		for (round in 0...rounds) {
			var s = subject(prefix, n, round);
			var re = new EReg("x(b+)(c+)$", "");
			if (!re.match(s) || re.matched(1) != "bbb" || re.matched(2) != "ccc")
				return false;
			var pos = re.matchedPos();
			if (pos.pos != prefix.length + n || pos.len != 7)
				return false;
			var two = re.matched(0);
			// A span that ends before the captures, then one that reaches them
			if (re.matchSub(s, 0, prefix.length + n))
				return false;
			if (!re.matchSub(s, 1, s.length - 1) || re.matchedPos().pos != pos.pos || re.matched(0) != two)
				return false;
		}
		return true;
	}

	// Long matches run in a GC-free zone while other threads collect, so the
	// subject and expression must stay alive and in place through the match
	static function main() {
		var collector = Thread.create(() -> {
			while (!stop.load()) {
				collecting.store(true);
				cpp.vm.Gc.compact();
				cpp.vm.Gc.run(true);
				// Lets the matching thread allocate between collections
				Sys.sleep(0.001);
			}
		});
		while (!collecting.load())
			Sys.sleep(0.001);
		// 2,000 ASCII characters and 1,500 UTF-16 ones stay below the large
		// allocation size, and both are long enough to match in the zone
		Sys.println("ASCII matches, captures and positions: " + check("", 2000, 200));
		Sys.println("UTF-16 matches, captures and positions: " + check("\u00e9", 1500, 300));
		Sys.println("long subjects: " + check("", 200000, 20) + " " + check("\u00e9", 200000, 20));
		Sys.println("short subjects: " + check("", 10, 3000) + " " + check("\u00e9", 10, 3000));
		stop.store(true);
		Sys.sleep(0.05);
	}
}
