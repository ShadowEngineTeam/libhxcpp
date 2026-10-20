import haxe.ds.IntMap;

// Int maps start on the identity hash and switch to a mixed hash, rehashing
// in place, once their keys collide (libhxcpp #231). This checks that every
// entry survives the switch whichever way it is triggered: a long chain on
// insert (strided keys), poor spread after growth (keys with a few zero low
// bits), or never (arithmetic keys). It also fails if strided keys are slow,
// which is what happens when the map never switches.
class Main {
	static var failures = 0;

	static function check(ok:Bool, what:String) {
		if (!ok && failures++ < 10)
			Sys.println("FAIL " + what);
	}

	static function exercise(name:String, n:Int, key:Int->Int) {
		var m = new IntMap<Int>();
		for (i in 0...n)
			m.set(key(i), i);
		for (i in 0...n)
			check(m.get(key(i)) == i, '$name get $i');
		// Overwrite a third, remove another third.
		for (i in 0...n)
			if (i % 3 == 0)
				m.set(key(i), -i);
		for (i in 0...n)
			if (i % 3 == 1)
				check(m.remove(key(i)), '$name remove $i');
		var count = 0;
		var sum = 0.0;
		for (k => v in m) {
			count++;
			sum += v;
		}
		var expectCount = 0;
		var expectSum = 0.0;
		for (i in 0...n) {
			var want:Null<Int> = switch (i % 3) {
				case 0: -i;
				case 1: null;
				case _: i;
			};
			check(m.get(key(i)) == want, '$name after $i');
			check(m.exists(key(i)) == (want != null), '$name exists $i');
			if (want != null) {
				expectCount++;
				expectSum += want;
			}
		}
		check(count == expectCount, '$name count $count');
		check(sum == expectSum, '$name sum');
		// Keys never inserted, many landing in occupied buckets.
		for (i in 0...100)
			check(!m.exists(key(n + i)), '$name miss $i');
		// Empty it (shrinks the bucket array) and refill.
		for (i in 0...n)
			m.remove(key(i));
		check(!m.keys().hasNext(), '$name empty');
		for (i in 0...n)
			m.set(key(i), i);
		for (i in 0...n)
			check(m.get(key(i)) == i, '$name refill $i');
	}

	static function main() {
		for (n in [10, 100, 5000, 100000]) {
			exercise('arith $n', n, i -> (i * 2579) ^ 0x2b5f3c1d);
			exercise('dense $n', n, i -> i);
			exercise('negative $n', n, i -> -i * 3);
			// Long chains under the identity hash: switches on insert.
			// (Keys stay below 2^31 so none overflow into duplicates.)
			exercise('stride14 $n', n, i -> i << 14);
			// Every 8th bucket only: switches when the map grows.
			exercise('stride8 $n', n, i -> (i << 3) + 0x10000000);
		}
		var t0 = haxe.Timer.stamp();
		exercise('timed', 200000, i -> i << 12);
		var seconds = haxe.Timer.stamp() - t0;
		// Takes milliseconds when the map switches, minutes when it doesn't.
		check(seconds < 10, 'strided keys took ${seconds}s');
		Sys.println(failures == 0 ? "int maps ok" : 'int maps FAILED ($failures)');
	}
}
