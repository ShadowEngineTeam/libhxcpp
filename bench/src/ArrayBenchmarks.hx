package;

import StringBenchmarks.Corpus;

/** Ints and Floats pushed onto Array<Dynamic>, the way untyped or JSON-like code fills one. **/
class ArrayPushDynamic extends Benchmark {
	static inline var N = 1000000;
	static inline var REPS = 4;

	public function new() {
		super("array_push_dynamic", "pushes", N, false, REPS);
	}

	override public function run():Int {
		var ints:Array<Dynamic> = [];
		var floats:Array<Dynamic> = [];
		for (i in 0...(N >> 1)) {
			ints.push(i + 1000);
			floats.push(i + 1000.5);
		}
		var at = (N >> 2) + 7;
		var a:Int = ints[at];
		var b:Float = floats[at];
		return (ints.length + floats.length + a + Std.int(b)) | 0;
	}
}

/** An empty Array<Dynamic> given its final capacity with NativeArray.reserve, then filled by index. **/
class ArrayReserveDynamic extends Benchmark {
	static inline var N = 1000000;
	static inline var REPS = 4;

	public function new() {
		super("array_reserve_dynamic", "elements", N, false, REPS);
	}

	override public function run():Int {
		var values:Array<Dynamic> = [];
		cpp.NativeArray.reserve(values, N);
		for (i in 0...N)
			values[i] = i + 1000;
		var last:Int = values[N - 1];
		return (values.length + last) | 0;
	}
}

/** A stack of Ints and one of Floats: two pushes and a pop per step, then drained with pop. **/
class ArrayPop extends Benchmark {
	static inline var N = 1000000;
	static inline var REPS = 4;

	public function new() {
		// N pops from each stack during the steps and N more draining it
		super("array_pop", "pops", N * 4, false, REPS);
	}

	override public function run():Int {
		var ints:Array<Int> = [];
		var floats:Array<Float> = [];
		var sum = 0;
		var fsum = 0.0;
		for (i in 0...N) {
			ints.push(1000 + (i & 1023));
			ints.push(2000 + (i & 511));
			var v:Int = ints.pop();
			sum = (sum + v) | 0;
			floats.push(1000.25 + (i & 1023));
			floats.push(2000.5 + (i & 511));
			var f:Float = floats.pop();
			fsum += f;
		}
		while (ints.length > 0) {
			var v:Int = ints.pop();
			sum = (sum * 3 + v) | 0;
		}
		while (floats.length > 0) {
			var f:Float = floats.pop();
			fsum += f;
		}
		return (sum + Std.int(fsum)) | 0;
	}
}

/** indexOf and lastIndexOf on an Array<Int> and a String from Int start positions, each finding a match a few elements away. **/
class SearchFrom extends Benchmark {
	static inline var N = 2000000;

	final values:Array<Int> = [];
	var text:String;

	public function new() {
		super("search_from", "searches", N * 4);
	}

	override public function setup() {
		for (i in 0...8192)
			values.push(i % 61);
		var b = new StringBuf();
		for (i in 0...1024)
			b.add(Corpus.words[i % Corpus.words.length] + ",");
		text = b.toString();
	}

	override public function run():Int {
		var sum = 0;
		var limit = text.length - 64;
		for (i in 0...N) {
			var from = 1000 + ((i * 7) & 4095);
			sum = (sum + values.indexOf((from + 5) % 61, from)) | 0;
			sum = (sum + values.lastIndexOf((from + 56) % 61, from)) | 0;
			var at = 300 + ((i * 13) % (limit - 300));
			sum = (sum + text.indexOf(",", at)) | 0;
			sum = (sum + text.lastIndexOf(",", at)) | 0;
		}
		return sum;
	}
}
