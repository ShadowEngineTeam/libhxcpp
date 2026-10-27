import cpp.NativeArray;
import cpp.vm.Gc;
import haxe.io.Bytes;
import haxe.io.BytesData;

// Large copies are made into buffers that are not cleared first, since
// the copy writes every byte. Recycled buffers hold old data, so each
// copy must still be exact, and other allocations still zero-filled.
class Main {
	static function dirtyCache(size:Int) {
		// Released at once into the recycle cache, full of 0xee
		for (i in 0...16) {
			var d:BytesData = [];
			NativeArray.setSize(d, size + (i & 3));
			for (j in 0...d.length)
				d[j] = 0xee;
			NativeArray.setSize(d, 0);
		}
	}

	static function pattern(n:Int, seed:Int):Bytes {
		var b = Bytes.alloc(n);
		for (i in 0...n)
			b.set(i, 32 + (i * 13 + seed) % 95);
		return b;
	}

	static function main() {
		var exact = true;
		var independent = true;
		var zeroed = true;
		var strings = true;
		for (round in 0...6) {
			var n = 100001 + round * 4099;
			dirtyCache(n);
			var src = pattern(n + 64, round);

			var sub = src.sub(3, n);
			for (i in 0...n)
				if (sub.get(i) != src.get(i + 3))
					exact = false;
			var copy = src.getData().copy();
			if (copy.length != n + 64)
				exact = false;
			for (i in 0...copy.length)
				if (copy[i] != src.get(i))
					exact = false;
			var from = Bytes.ofData(src.getData().slice(1, n + 1));
			for (i in 0...n)
				if (from.get(i) != src.get(i + 1))
					exact = false;

			sub.set(0, 1);
			copy[1] = 2;
			if (src.get(3) == 1 || src.get(1) == 2)
				independent = false;

			var text = src.getString(5, n);
			if (text.length != n)
				strings = false;
			for (i in 0...n)
				if (StringTools.fastCodeAt(text, i) != src.get(i + 5))
					strings = false;
			// Non-ASCII text takes the UTF-16 path
			var wide = text.substr(0, 9000) + "é" + text.substr(9000, 9000);
			var wideCopy = wide.substr(1, 18000);
			if (wideCopy.length != 18000 || wideCopy.charCodeAt(8999) != 0xe9 || wideCopy.charCodeAt(0) != wide.charCodeAt(1))
				strings = false;
			// The memoized hash slot must start out unset
			var map = new Map<String, Int>();
			map.set(text, round);
			if (map.get(src.getString(5, n)) != round)
				strings = false;

			Gc.run(false);
			dirtyCache(n);
			var fresh = Bytes.alloc(n);
			for (i in 0...n)
				if (fresh.get(i) != 0)
					zeroed = false;
			var grown:BytesData = [];
			NativeArray.setSize(grown, n);
			for (i in 0...n)
				if (grown[i] != 0)
					zeroed = false;
		}
		Sys.println("large copies are exact: " + exact);
		Sys.println("copies are independent of their source: " + independent);
		Sys.println("large string copies are exact and hash alike: " + strings);
		Sys.println("other large allocations are zero-filled: " + zeroed);
	}
}
