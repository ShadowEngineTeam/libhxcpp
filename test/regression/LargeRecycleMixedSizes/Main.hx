import cpp.NativeArray;
import cpp.vm.Gc;
import haxe.io.Bytes;
import haxe.io.BytesData;

// The recycle cache holds buffers of many sizes. A buffer taken from it
// must be of the size asked for, zero-filled when it is a new allocation,
// and not handed out twice.
class Main {
	static var retained:Bytes;

	static function seed() {
		var a = [for (i in 0...3000) Bytes.alloc(4000 + 4 * (i % 97))];
		for (b in a)
			b.fill(0, b.length, 0xa5);
	}

	static function main() {
		retained = Bytes.alloc(64 * 1024);
		for (i in 0...retained.length)
			retained.set(i, i % 253);
		seed();
		Gc.run(false);

		var cleared = true;
		var sized = true;
		var distinct = true;
		for (round in 0...20) {
			var live = [];
			for (i in 0...200) {
				var size = 4000 + 4 * ((i * 31 + round) % 97);
				var b = Bytes.alloc(size);
				if (b.length != size)
					sized = false;
				for (j in 0...size)
					if (b.get(j) != 0) {
						cleared = false;
						break;
					}
				b.fill(0, size, round + 1);
				live.push(b);
			}
			// Released at once by an exact resize, into the cache
			for (i in 0...100) {
				var d:BytesData = [];
				NativeArray.setSize(d, 4000 + 4 * (i % 97));
				d[0] = 9;
				NativeArray.setSize(d, 0);
			}
			for (i in 0...live.length) {
				var b = live[i];
				if (b.get(0) != round + 1 || b.get(b.length - 1) != round + 1)
					distinct = false;
			}
			if (round % 5 == 4)
				Gc.run(false);
		}
		var kept = true;
		for (i in 0...retained.length)
			if (retained.get(i) != i % 253)
				kept = false;
		Sys.println("recycled buffers have the size asked for: " + sized);
		Sys.println("recycled buffers are zero-filled: " + cleared);
		Sys.println("no buffer is handed out twice: " + distinct);
		Sys.println("a retained buffer survives the churn: " + kept);
	}
}
