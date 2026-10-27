package;

enum Chain {
	End;
	Link(next:Chain);
	Pair(left:Chain, right:Int);
}

/** Std.string on a deeply nested enum, as a debug print of a list or syntax tree. **/
class EnumFormat extends Benchmark {
	static inline var DEPTH = 2048;
	static inline var REPS = 16;

	var value:Chain;

	public function new() {
		super("enum_format", "enum values", DEPTH * REPS);
	}

	override public function setup() {
		value = End;
		for (i in 0...DEPTH)
			value = (i & 1) == 0 ? Link(value) : Pair(value, i);
	}

	override public function run():Int {
		var sum = 0;
		for (r in 0...REPS) {
			var s = Std.string(value);
			var mid:Int = s.charCodeAt(s.length >> 1);
			sum = (sum * 31 + s.length + mid) | 0;
		}
		return sum;
	}
}
