import cpp.vm.Gc;
import cpp.vm.WeakRef;
import haxe.Int64;
import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;
import haxe.io.Bytes;
import sys.thread.Deque;
import sys.thread.Lock;
import sys.thread.Mutex;
import sys.thread.Thread;

class Rng {
	var state:Int;

	public function new(seed:Int) {
		state = seed == 0 ? 0x2545F491 : seed;
	}

	public function next():Int {
		state ^= state << 13;
		state ^= state >>> 17;
		state ^= state << 5;
		return state & 0x7fffffff;
	}

	public inline function below(n:Int):Int {
		return next() % n;
	}
}

class Node {
	public final id:Int;
	public final value:Int;
	public final label:String;
	public final weight:Float;
	public final fn:Void->Int;
	public var kids:Array<Node> = [];
	public var payload:Dynamic;
	public var payloadSum:Int = 0;
	public var shared = false;

	public function new(id:Int, value:Int) {
		this.id = id;
		this.value = value;
		label = labelFor(id);
		weight = id * 0.5;
		fn = () -> value + id;
	}

	public static function labelFor(id:Int):String {
		return "n" + id + "_" + StringTools.hex(id * 31);
	}

	public function check():Null<String> {
		if (label != labelFor(id))
			return 'node $id has label $label';
		if (weight != id * 0.5)
			return 'node $id has weight $weight';
		if (fn() != value + id)
			return 'node $id closure returned ${fn()}';
		for (k in kids)
			if (k == null)
				return 'node $id has a null kid';
		if (payload != null && Payload.sum(payload) != payloadSum)
			return 'node $id payload sums to ${Payload.sum(payload)}, not $payloadSum';
		return null;
	}
}

class Payload {
	public static function make(rng:Rng, id:Int, large:Bool):Dynamic {
		if (large) {
			var b = Bytes.alloc(65536 + rng.below(262144));
			for (i in 0...b.length)
				b.set(i, (id + i) & 255);
			return b;
		}
		return switch (rng.below(7)) {
			case 0: "p" + id + StringTools.lpad("", "x", rng.below(200));
			case 1: [for (i in 0...rng.below(300)) i * id];
			case 2:
				var b = Bytes.alloc(rng.below(4096));
				for (i in 0...b.length)
					b.set(i, (id + i) & 255);
				b;
			case 3: {a: id, b: [for (i in 0...rng.below(20)) "s" + i], c: id * 1.25};
			case 4: Int64.make(id, id * 3);
			case 5: [for (i in 0...rng.below(100)) i * 0.5];
			default: id * 2.5;
		}
	}

	public static function sum(p:Dynamic):Int {
		if (Std.isOfType(p, String)) {
			var s:String = p;
			return s.length * 7 + s.charCodeAt(0);
		}
		if (Std.isOfType(p, Bytes)) {
			var b:Bytes = p;
			var t = b.length;
			var i = 0;
			while (i < b.length) {
				t = (t * 31 + b.get(i)) | 0;
				i += 997;
			}
			return t;
		}
		if (Std.isOfType(p, Array)) {
			var a:Array<Dynamic> = p;
			var t = a.length;
			for (v in a)
				t = (t * 31 + Std.int((v : Float) * 2)) | 0;
			return t;
		}
		if (Int64.isInt64(p)) {
			var v:Int64 = p;
			return v.high * 5 + v.low;
		}
		if (Std.isOfType(p, Float))
			return Std.int((p : Float) * 4);
		var a:Int = p.a;
		var b:Array<String> = p.b;
		var c:Float = p.c;
		return a * 3 + b.length + Std.int(c * 4) + b.join("").length;
	}
}

class Worker {
	static inline var GRAPH = 3000;

	public final index:Int;

	final rng:Rng;
	final graph:Array<Node> = [];
	final weak:Array<WeakRef<Node>> = [];
	final weakSlot:Array<Int> = [];
	final weakId:Array<Int> = [];
	final byLabel = new Map<String, Node>();
	final byId = new Map<Int, Node>();
	final byObject = new ObjectMap<Node, Int>();
	final weakMap = new WeakMap<Node, Int>();
	final floats:Array<Float> = [];
	final strings:Array<String> = [];
	var nextId:Int;

	public var ops(default, null) = 0;
	public var finalizers(default, null) = 0;

	public function new(index:Int, seed:Int) {
		this.index = index;
		rng = new Rng(seed);
		nextId = index * 100000000;
		for (i in 0...GRAPH)
			graph.push(newNode());
	}

	function newNode():Node {
		var n = new Node(nextId++, rng.next() & 0xffff);
		var links = rng.below(4);
		for (i in 0...links)
			if (graph.length > 0)
				n.kids.push(graph[rng.below(graph.length)]);
		return n;
	}

	function owned():Node {
		var n = graph[rng.below(graph.length)];
		return n.shared ? null : n;
	}

	public function step():Null<String> {
		ops++;
		var r = rng.below(100);
		if (r < 35) {
			var slot = rng.below(graph.length);
			var old = graph[slot];
			var n = newNode();
			graph[slot] = n;
			if (!old.shared) {
				old.kids = rng.below(4) == 0 ? [n] : [];
			}
			if (rng.below(50) == 0)
				Gc.doNotKill(old);
		} else if (r < 50) {
			var a = owned();
			if (a != null) {
				var b = graph[rng.below(graph.length)];
				if (a.kids.length > 0 && rng.below(2) == 0)
					a.kids[rng.below(a.kids.length)] = b;
				else if (a.kids.length < 8)
					a.kids.push(b);
				else
					a.kids.splice(rng.below(a.kids.length), 1);
			}
		} else if (r < 62) {
			var n = owned();
			if (n != null) {
				n.payload = Payload.make(rng, n.id, rng.below(2000) == 0);
				n.payloadSum = Payload.sum(n.payload);
			}
		} else if (r < 70) {
			var n = graph[rng.below(graph.length)];
			byLabel.set(n.label, n);
			byId.set(n.id, n);
			byObject.set(n, n.id);
			weakMap.set(n, n.id);
			var probe = graph[rng.below(graph.length)];
			var hit = byLabel.get(probe.label);
			if (hit != null && hit.label != probe.label)
				return 'StringMap returned ${hit.label} for ${probe.label}';
			var idHit = byId.get(probe.id);
			if (idHit != null && idHit.id != probe.id)
				return 'IntMap returned ${idHit.id} for ${probe.id}';
			if (byObject.exists(probe) && byObject.get(probe) != probe.id)
				return 'ObjectMap lost ${probe.id}';
			if (weakMap.exists(probe) && weakMap.get(probe) != probe.id)
				return 'WeakMap lost ${probe.id}';
			if (rng.below(50) == 0) {
				byLabel.clear();
				byId.clear();
				byObject.clear();
			}
		} else if (r < 76) {
			var slot = rng.below(graph.length);
			if (weak.length < 64) {
				weak.push(new WeakRef(graph[slot]));
				weakSlot.push(slot);
				weakId.push(graph[slot].id);
			} else {
				var w = rng.below(weak.length);
				var target = weak[w].get();
				var live = graph[weakSlot[w]];
				if (live.id == weakId[w] && target != live)
					return 'weak ref to live node ${weakId[w]} returned ${target == null ? "null" : "" + target.id}';
				if (target != null) {
					var err = target.check();
					if (err != null)
						return 'weak target: $err';
				}
				weak[w] = new WeakRef(graph[slot]);
				weakSlot[w] = slot;
				weakId[w] = graph[slot].id;
			}
		} else if (r < 80) {
			var n = newNode();
			Gc.setFinalizer(n, cpp.Callable.fromStaticFunction(Stress.finalized));
			finalizers++;
			if (rng.below(2) == 0)
				graph[rng.below(graph.length)] = n;
		} else if (r < 83) {
			Gc.enterGCFreeZone();
			var t = 0;
			for (i in 0...rng.below(20000))
				t += i;
			Gc.exitGCFreeZone();
			if (t < 0)
				return "free zone arithmetic";
		} else if (r < 89) {
			switch (rng.below(4)) {
				case 0:
					floats.push(rng.next() * 0.25);
					if (floats.length > 5000)
						floats.splice(0, 2500);
				case 1:
					strings.push(Node.labelFor(rng.next()));
					if (strings.length > 2000) {
						strings.sort(Reflect.compare);
						for (i in 1...strings.length)
							if (strings[i - 1] > strings[i])
								return "string sort out of order";
						strings.splice(rng.below(1000), 1000);
					}
				case 2:
					var s = graph.slice(rng.below(graph.length));
					var c = s.concat(graph.slice(0, 10));
					if (c.length != s.length + 10)
						return "concat length";
				default:
					var copy = graph.copy();
					copy.reverse();
					if (copy[0] != graph[graph.length - 1])
						return "reverse copy";
			}
		} else if (r < 95) {
			var b = new StringBuf();
			var parts = rng.below(50) + 1;
			for (i in 0...parts)
				b.add(Node.labelFor(i));
			var joined = b.toString();
			var expected = [for (i in 0...parts) Node.labelFor(i)].join("");
			if (joined != expected)
				return "StringBuf result";
			if (joined.split("_").length != parts + 1)
				return "split count";
		} else if (r < 99) {
			var n = owned();
			if (n != null && rng.below(2) == 0) {
				n.kids = [];
				n.shared = true;
				Stress.exchange.add(n);
			} else {
				var other = Stress.exchange.pop(false);
				if (other != null) {
					var err = other.check();
					if (err != null)
						return 'shared node: $err';
					var mine = owned();
					if (mine != null && mine.kids.length < 8)
						mine.kids.push(other);
				}
			}
		} else {
			var done = new Lock();
			var id = nextId++;
			var result:Array<Node> = [];
			Thread.create(() -> {
				var n = new Node(id, 7);
				n.kids = [for (i in 0...200) new Node(id, i)];
				result.push(n);
				done.release();
			});
			done.wait();
			var err = result[0].check();
			if (err != null)
				return 'node from a short-lived thread: $err';
			graph[rng.below(graph.length)] = result[0];
		}

		if (ops % 2000 == 0)
			return checkAll();
		return null;
	}

	public function reachable(seen:ObjectMap<Node, Bool>):Int {
		var stack = graph.copy();
		var count = 0;
		while (stack.length > 0) {
			var n = stack.pop();
			if (seen.exists(n))
				continue;
			seen.set(n, true);
			count++;
			for (k in n.kids)
				stack.push(k);
		}
		return count;
	}

	public function checkAll():Null<String> {
		for (n in graph) {
			var err = n.check();
			if (err != null)
				return err;
			for (k in n.kids) {
				err = k.check();
				if (err != null)
					return 'kid of ${n.id}: $err';
				for (kk in k.kids)
					if (kk == null || kk.label != Node.labelFor(kk.id))
						return 'grandkid of ${n.id} is corrupt';
			}
		}
		return null;
	}
}

class Stress {
	public static final exchange = new Deque<Node>();
	public static var finalizerRuns = 0;

	static final mutex = new Mutex();
	static var failure:Null<String> = null;
	// Read and written under mutex: the workers poll it while others set it
	static var stop = false;

	static function stopped():Bool {
		mutex.acquire();
		var result = stop;
		mutex.release();
		return result;
	}

	public static function finalized(n:Node):Void {
		finalizerRuns++;
	}

	static function fail(message:String) {
		mutex.acquire();
		if (failure == null)
			failure = message;
		stop = true;
		mutex.release();
	}

	public static function main() {
		untyped __cpp__("setvbuf(stdout, NULL, _IONBF, 0)");
		var args = Sys.args();
		var seconds = args.length > 0 ? Std.parseFloat(args[0]) : 10.0;
		var threads = args.length > 1 ? Std.parseInt(args[1]) : 4;
		var seed = args.length > 2 ? Std.parseInt(args[2]) : Std.int(Sys.time() * 1000) & 0x7fffffff;
		Sys.println('gc stress: $seconds s, $threads threads, seed $seed');

		var finished = new Lock();
		var workers = [];
		for (t in 0...threads) {
			var w = new Worker(t, seed + t * 7919);
			workers.push(w);
			Thread.create(() -> {
				try {
					while (!stopped()) {
						var err = w.step();
						if (err != null)
							fail('worker ${w.index}: $err');
					}
					var err = w.checkAll();
					if (err != null)
						fail('worker ${w.index} at exit: $err');
				} catch (e:Dynamic) {
					fail('worker ${w.index} threw $e');
				}
				finished.release();
			});
		}

		var rng = new Rng(seed ^ 0x5bd1e995);
		var deadline = Sys.time() + seconds;
		var collections = 0;
		var zombies = 0;
		while (!stopped() && Sys.time() < deadline) {
			switch (rng.below(10)) {
				case 0: Gc.run(true);
				case 1: Gc.run(false);
				case 2 if (rng.below(10) == 0): Gc.compact();
				default:
			}
			collections++;
			var z:Node = Gc.getNextZombie();
			while (z != null) {
				zombies++;
				if (z.label != Node.labelFor(z.id))
					fail('zombie ${z.id} is corrupt');
				z = Gc.getNextZombie();
			}
			Sys.sleep(0.002);
		}
		mutex.acquire();
		stop = true;
		mutex.release();
		for (t in 0...threads)
			finished.wait();

		Gc.run(true);
		var ops = 0;
		var registeredFinalizers = 0;
		for (w in workers) {
			ops += w.ops;
			registeredFinalizers += w.finalizers;
			var err = w.checkAll();
			if (err != null && failure == null)
				failure = 'worker ${w.index} after the last collection: $err';
		}
		var seen = new ObjectMap<Node, Bool>();
		var reachable = 0;
		for (w in workers)
			reachable += w.reachable(seen);
		seen = null;
		if (finalizerRuns > registeredFinalizers)
			failure = 'ran $finalizerRuns finalizers for $registeredFinalizers objects';

		Sys.println('$ops operations, $collections collection requests, $zombies zombies, '
			+ '$finalizerRuns of $registeredFinalizers finalizers ran, $reachable nodes reachable, '
			+ '${Std.int(Gc.memInfo64(Gc.MEM_INFO_USAGE) / 1048576)} MB in use');
		if (failure != null) {
			Sys.println('FAILED (seed $seed): $failure');
			Sys.exit(1);
		}
		Sys.println("ok");
		#if HXCPP_GC_INCREMENTAL
		Sys.println("incremental " + haxe.Json.stringify(hxcpp.gc.Incremental.getStats()));
		#end
	}
}
