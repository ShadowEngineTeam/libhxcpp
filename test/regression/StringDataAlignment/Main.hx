// String data may start 4 bytes into 8, but objects and data that hold doubles
// or atomics must still start 8-byte aligned, and a collector that walks the
// heap from header to header (the nursery) must still find every object
// between such strings (libhxcpp #370). The same source builds with the
// default, generational and always-moving collectors.
class Wide {
	public var f:Float;
	public var i:haxe.Int64;
	public var n:Int;

	public function new(n:Int) {
		this.n = n;
		f = n + 0.5;
		i = haxe.Int64.make(n, n * 3);
	}

	public function check(n:Int):Bool
		return this.n == n && f == n + 0.5 && i == haxe.Int64.make(n, n * 3);
}

class Main {
	static var misaligned = 0;
	static var shortStrings = 0;
	static var failures = 0;

	static function makeString(len:Int, wide:Bool):String {
		var b = new StringBuf();
		for (c in 0...len)
			b.addChar(wide && c % 3 == 0 ? 0x4e00 + c : 0x41 + (len + c) % 26);
		return b.toString();
	}

	static function checkString(s:String, len:Int, wide:Bool):Bool {
		if (s.length != len)
			return false;
		for (c in 0...len)
			if (s.charCodeAt(c) != (wide && c % 3 == 0 ? 0x4e00 + c : 0x41 + (len + c) % 26))
				return false;
		return true;
	}

	static function aligned(o:Dynamic):Bool
		return untyped __cpp__("(((size_t){0}.mPtr) & 7) == 0", o);

	static function dataAligned(a:Array<Float>):Bool
		return untyped __cpp__("(((size_t){0}->GetBase()) & 7) == 0", a);

	static function int64DataAligned(a:Array<haxe.Int64>):Bool
		return untyped __cpp__("(((size_t){0}->GetBase()) & 7) == 0", a);

	static function stringAt4(s:String):Bool
		return untyped __cpp__("(((size_t){0}.raw_ptr()) & 7) == 4", s);

	static function checkAlignment(w:Wide, floats:Array<Float>, longs:Array<haxe.Int64>) {
		if (!aligned(w) || !aligned(floats) || !dataAligned(floats) || !int64DataAligned(longs))
			misaligned++;
	}

	// Every string, object and array here is held only by this frame's locals,
	// so a collection finds them through the conservative stack scan. In the
	// nursery that walks each hole from header to header past the strings
	static function nest(depth:Int) {
		var len = depth % 80;
		var narrow = makeString(len, false);
		var w = new Wide(depth);
		var wide = makeString(len, true);
		var floats = [depth + 0.25, depth + 0.75];
		var tail = makeString((len * 7) % 23, false);
		var longs = [haxe.Int64.make(depth, 7)];
		checkAlignment(w, floats, longs);
		if (stringAt4(narrow) || stringAt4(wide) || stringAt4(tail))
			shortStrings++;

		if (depth < 240)
			nest(depth + 1);
		else
			churn();

		checkAlignment(w, floats, longs);
		if (!checkString(narrow, len, false) || !checkString(wide, len, true) || !checkString(tail, (len * 7) % 23, false))
			failures++;
		if (!w.check(depth) || floats[0] != depth + 0.25 || floats[1] != depth + 0.75 || longs[0] != haxe.Int64.make(depth, 7))
			failures++;
	}

	// Collects, then fills the freed space with other data, which would
	// overwrite anything the collection missed
	static function churn() {
		for (round in 0...4) {
			cpp.vm.Gc.run(round == 3);
			var garbage:Array<Dynamic> = [];
			for (i in 0...20000) {
				garbage.push(new Wide(-i));
				garbage.push(makeString(i % 37, i % 2 == 0));
			}
			garbage = null;
		}
		cpp.vm.Gc.compact();
	}

	static function main() {
		// Strings of every short length, both encodings, among objects and
		// arrays that hold doubles and Int64s, held by the heap
		var strings = [];
		var objects = [];
		var floatArrays = [];
		var longArrays = [];
		for (len in 0...300) {
			strings.push(makeString(len, false));
			objects.push(new Wide(len));
			strings.push(makeString(len, true));
			floatArrays.push([len * 1.5]);
			longArrays.push([haxe.Int64.make(len, len)]);
		}
		for (i in 0...objects.length)
			checkAlignment(objects[i], floatArrays[i], longArrays[i]);
		for (s in strings)
			if (stringAt4(s))
				shortStrings++;

		nest(0);

		// String keys with memoized hashes, from both encodings
		var map = new Map<String, Int>();
		for (i in 0...strings.length)
			map.set(strings[i], i);
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.compact();
		for (i in 0...strings.length)
			if (!checkString(strings[i], i >> 1, i % 2 == 1) || (i >= 2 && map.get(makeString(i >> 1, i % 2 == 1)) != i))
				failures++;
		for (i in 0...objects.length) {
			checkAlignment(objects[i], floatArrays[i], longArrays[i]);
			if (!objects[i].check(i) || floatArrays[i][0] != i * 1.5 || longArrays[i][0] != haxe.Int64.make(i, i))
				failures++;
		}

		Sys.println('objects and arrays of Floats and Int64s start 8-byte aligned: ${misaligned == 0}');
		Sys.println('string data can start 4 bytes into 8: ${shortStrings > 0}');
		Sys.println('every string, object and array keeps its values: ${failures == 0}');
	}
}
