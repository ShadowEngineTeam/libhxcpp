import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;

// Maps shrink their bucket array as keys are removed (libhxcpp #225 moved the
// threshold from half full to a quarter full). This drives Int, String and
// Object maps through repeated grow / shrink-to-empty / regrow cycles across
// several sizes and checks every key and value at each stage, so a mistake in
// compact() (lost or misplaced entries) shows up as wrong output.
class Key {
	public var id:Int;

	public function new(id:Int)
		this.id = id;
}

class Main {
	static var failures = 0;

	static function check(ok:Bool, what:String) {
		if (!ok && failures++ < 10)
			Sys.println("FAIL " + what);
	}

	static function intMap(n:Int) {
		var m = new IntMap<Int>();
		for (cycle in 0...3) {
			for (i in 0...n)
				m.set(i * 7919, i);
			// Remove from the front so compaction runs while keys remain.
			for (i in 0...n) {
				check(m.remove(i * 7919), 'int remove $n $i');
				if (i % 97 == 0)
					for (j in (i + 1)...n)
						if (m.get(j * 7919) != j) {
							check(false, 'int lost $n $i $j');
							break;
						}
			}
			for (i in 0...n)
				check(!m.exists(i * 7919), 'int stale $n $i');
			// Half back, then remove every other one, then the rest.
			for (i in 0...(n >> 1))
				m.set(i * 7919, -i);
			for (i in 0...(n >> 1))
				if (i & 1 == 0)
					check(m.remove(i * 7919), 'int remove2 $n $i');
			for (i in 0...(n >> 1))
				check(m.get(i * 7919) == (i & 1 == 0 ? null : -i), 'int mixed $n $i');
			for (i in 0...(n >> 1))
				m.remove(i * 7919);
			check(!m.keys().hasNext(), 'int empty $n $cycle');
		}
	}

	static function stringMap(n:Int) {
		var m = new StringMap<Int>();
		for (cycle in 0...3) {
			for (i in 0...n)
				m.set("k" + i, i);
			for (i in 0...n) {
				check(m.remove("k" + i), 'string remove $n $i');
				if (i % 97 == 0)
					for (j in (i + 1)...n)
						if (m.get("k" + j) != j) {
							check(false, 'string lost $n $i $j');
							break;
						}
			}
			var count = 0;
			for (_ in m.keys())
				count++;
			check(count == 0, 'string empty $n $cycle');
		}
	}

	static function objectMap(n:Int) {
		var keys = [for (i in 0...n) new Key(i)];
		var m = new ObjectMap<Key, Int>();
		for (cycle in 0...3) {
			for (k in keys)
				m.set(k, k.id);
			for (i in 0...n) {
				check(m.remove(keys[i]), 'object remove $n $i');
				if (i % 97 == 0)
					for (j in (i + 1)...n)
						if (m.get(keys[j]) != j) {
							check(false, 'object lost $n $i $j');
							break;
						}
			}
			check(!m.keys().hasNext(), 'object empty $n $cycle');
		}
	}

	static function main() {
		// Sizes either side of the 2x and 4x growth steps (4096 buckets).
		for (n in [9, 100, 1000, 4097, 5000, 20000, 70000]) {
			intMap(n);
			stringMap(n);
			objectMap(n);
		}
		Sys.println(failures == 0 ? "maps ok" : 'maps FAILED ($failures)');
	}
}
