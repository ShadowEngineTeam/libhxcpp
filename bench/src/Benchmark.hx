package;

/**
	One benchmark. The harness calls setup() once, untimed, then run() for
	the warmup and timed samples.

	run() returns a checksum of the work it did. The harness folds the
	checksums of every call together, and the driver requires the same
	result from every process under both runtimes. A change that skips
	work or computes the wrong answer can't look faster that way.
**/
class Benchmark {
	public final name:String;

	/** What one operation is, e.g. "objects" or "elements". **/
	public final unit:String;

	/** Operations done by one call to run(). **/
	public final ops:Float;

	/** If true, run() fills `latencies` with the duration of each work unit, in seconds. **/
	public final measuresLatency:Bool;

	/** How many times the harness calls run() in one timed sample. ops already counts all of them. **/
	public final reps:Int;

	public var latencies:Null<Array<Float>> = null;

	public function new(name:String, unit:String, ops:Float, measuresLatency = false, reps = 1) {
		this.name = name;
		this.unit = unit;
		this.ops = ops * reps;
		this.reps = reps;
		this.measuresLatency = measuresLatency;
	}

	public function setup():Void {}

	public function run():Int {
		return 0;
	}
}

/** xorshift32 with a fixed seed, so every run does exactly the same work. **/
class Rng {
	var state:Int;

	public function new(seed:Int) {
		state = seed == 0 ? 0x2545F491 : seed;
	}

	public inline function next():Int {
		state ^= state << 13;
		state ^= state >>> 17;
		state ^= state << 5;
		return state & 0x7fffffff;
	}

	public inline function below(n:Int):Int {
		return next() % n;
	}
}
