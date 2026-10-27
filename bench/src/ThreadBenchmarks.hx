package;

import sys.thread.Deque;

/**
	A deque filled at the front, as a work queue that puts urgent items
	first, then drained. Messages are the shared boxed 7, so no allocation
	per message is timed.
**/
class DequePush extends Benchmark {
	static inline var N = 65536;

	public function new() {
		super("deque_push", "messages", N * 2);
	}

	override public function run():Int {
		var q = new Deque<Dynamic>();
		for (i in 0...N)
			q.push(7);
		var sum = 0;
		for (i in 0...N)
			sum = (sum + (q.pop(false) : Int)) | 0;
		if (q.pop(false) != null)
			throw "queue not empty";
		return sum;
	}
}

/**
	Repeated bursts through one long-lived deque: a mailbox that fills up,
	drains completely and fills up again. Kept to 8,192 messages, as stock
	hxcpp moves the whole queue for every pop.
**/
class DequeBurst extends Benchmark {
	static inline var N = 8192;
	static inline var BURSTS = 20;

	final q = new Deque<Dynamic>();

	public function new() {
		super("deque_burst", "messages", N * 2 * BURSTS);
	}

	override public function run():Int {
		var sum = 0;
		for (b in 0...BURSTS) {
			for (i in 0...N)
				q.add(7);
			for (i in 0...N)
				sum = (sum + (q.pop(false) : Int)) | 0;
		}
		if (q.pop(false) != null)
			throw "queue not empty";
		return sum;
	}
}
