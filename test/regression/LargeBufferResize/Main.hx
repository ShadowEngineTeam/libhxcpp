import cpp.NativeArray;
import cpp.vm.Gc;
import haxe.io.Bytes;
import haxe.io.BytesData;

// Exact resizes release the old buffer at once, into the recycle cache.
// The released buffer is found by the place it keeps in the allocator's
// list, which moves as other large allocations come and go.
class Main {
	static var neighbours:Array<Bytes>;
	static var targets:Array<BytesData>;

	static function seed() {
		var a = [for (i in 0...64) Bytes.alloc(4096 + 4 * (i & 3))];
		a[0].set(0, 1);
	}

	static function fill(d:BytesData, from:Int, seed:Int) {
		for (i in from...d.length)
			d[i] = (i * 7 + seed) & 255;
	}

	static function check(d:BytesData, seed:Int):Bool {
		for (i in 0...d.length)
			if (d[i] != (i * 7 + seed) & 255)
				return false;
		return true;
	}

	static function resizeAll(rounds:Int):Bool {
		var ok = true;
		for (r in 0...rounds) {
			for (t in 0...targets.length) {
				var d = targets[t];
				var old = d.length;
				var size = 4096 + ((r + t) % 3) * 4;
				NativeArray.setSize(d, size);
				// Growth is zero-filled, and kept bytes survive
				for (i in old...size)
					if (d[i] != 0)
						ok = false;
				for (i in 0...(old < size ? old : size))
					if (d[i] != (i * 7 + t) & 255)
						ok = false;
				fill(d, old < size ? old : size, t);
			}
		}
		return ok;
	}

	static function main() {
		seed();
		Gc.run(false);
		targets = [];
		// Old targets, before the neighbours, then young ones after a collection
		for (t in 0...8) {
			var d:BytesData = [];
			NativeArray.setSize(d, 4096);
			fill(d, 0, t);
			targets.push(d);
		}
		neighbours = [];
		for (i in 0...2000) {
			var b = Bytes.alloc(4096 + 8 * (i % 5));
			b.set(0, i % 251);
			b.set(b.length - 1, (i + 3) % 251);
			neighbours.push(b);
		}
		Gc.run(false);
		for (t in 8...16) {
			var d:BytesData = [];
			NativeArray.setSize(d, 4096);
			fill(d, 0, t);
			targets.push(d);
		}
		var ok = resizeAll(200);
		Sys.println("resized buffers keep their bytes and zero their growth: " + ok);
		// Drop every other neighbour, so the list is reordered under the targets
		for (i in 0...neighbours.length)
			if ((i & 1) == 1)
				neighbours[i] = neighbours[i - 1];
		Gc.run(false);
		var neighboursOk = true;
		for (i in 0...neighbours.length) {
			var j = i & ~1;
			var b = neighbours[i];
			if (b.get(0) != j % 251 || b.get(b.length - 1) != (j + 3) % 251)
				neighboursOk = false;
		}
		ok = resizeAll(200);
		Gc.run(true);
		for (t in 0...targets.length)
			if (!check(targets[t], t))
				ok = false;
		Sys.println("resizes after the list changed still work: " + ok);
		Sys.println("neighbouring buffers survive collection: " + neighboursOk);
	}
}
