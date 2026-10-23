import haxe.ds.WeakMap;
import cpp.vm.Gc;
import cpp.vm.WeakRef;
import sys.thread.Lock;
import sys.thread.Thread;

class Key {
	public var id:Int;

	public function new(id:Int)
		this.id = id;
}

// Weak maps whose entries lead from one to the next: map i holds key[i] ->
// key[i + 1]. A value is reachable only while its map and its key are, so with
// key[0] held the whole chain survives, and with nothing held none of it does,
// whichever order the maps were registered in (libhxcpp #203).
class Main {
	static var root:Key;
	static var maps:Array<WeakMap<Key, Key>>;

	static function build(n:Int, reverse:Bool, hold:Bool):WeakRef<Key> {
		var keys = [for (i in 0...n + 1) new Key(i)];
		maps = [for (i in 0...n) null];
		for (k in 0...n) {
			var i = reverse ? n - 1 - k : k;
			var m = new WeakMap<Key, Key>();
			m.set(keys[i], keys[i + 1]);
			maps[i] = m;
		}
		root = hold ? keys[0] : null;
		return new WeakRef(keys[n]);
	}

	// Builds a chain that nothing holds on a thread that then ends, so no key
	// is left on a scanned stack or in a register when the collection runs
	static function buildOnThread(n:Int, reverse:Bool):WeakRef<Key> {
		var dropped:WeakRef<Key> = null;
		var built = new Lock();
		Thread.create(() -> {
			dropped = build(n, reverse, false);
			built.release();
		});
		built.wait();
		// Let the thread finish and leave the collector's list of threads
		Sys.sleep(0.2);
		return dropped;
	}

	static function main() {
		for (reverse in [false, true]) {
			var held = build(1000, reverse, true);
			Gc.run(true);
			var chainKept = held.get() != null;
			var dropped = buildOnThread(1000, reverse);
			Gc.run(true);
			Gc.run(true);
			Sys.println((reverse ? "reverse" : "forward") + ": held chain kept " + chainKept + ", dropped chain collected " + (dropped.get() == null));
		}
	}
}
