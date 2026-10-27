// A Float prints with the fewest digits that read back as it. Denormals took
// 15 digits ("4.94065645841247e-324"), and some powers of two one more than
// they need.
function main() {
	for (text in ["5e-324", "5e-310", "5.960464477539063e-8", "2.2250738585072014e-308", "1.7976931348623157e+308", "1e+23", "1e+16", "123456789012345",
		"1e-5", "0.0001", "-0", "-1.5"])
		Sys.println(Std.string(Std.parseFloat(text)));
	Sys.println(0.1 + 0.2);
	Sys.println(1 / 3);

	// Powers of two and the doubles either side, whose lower neighbour is
	// nearer, and values that a fast shortest-digit search has to leave to an
	// exact one (libhxcpp #390)
	for (bits in [[0, 1], [0, 0x100000], [0xffffffff, 0xfffff], [0, 0x3ff00000], [0xffffffff, 0x3fefffff], [1, 0x3ff00000],
		[0, 0x43400000], [0xffffffff, 0x433fffff], [1, 0x43400000], [0, 0x7fe00000], [0xffffffff, 0x7fdfffff], [0, 0x44b52d02],
		[0x6c3b8a3e, 0x4415af1d], [0xc4ce5f3c, 0x3e7ad7f2], [0x9999999a, 0x3fb99999]])
		Sys.println(haxe.io.FPHelper.i64ToDouble(bits[0], bits[1]));

	var seed = 12345;
	function next() {
		seed = (seed * 1103515245 + 12345) & 0x7fffffff;
		return seed;
	}
	var readBack = true;
	for (i in 0...100000) {
		var high = next() & (i % 2 == 0 ? 0xfffff : 0x7fefffff);
		var value = haxe.io.FPHelper.i64ToDouble(next() * 2 + (next() & 1), high);
		if (Std.parseFloat(Std.string(value)) != value) {
			Sys.println("does not read back: " + value);
			readBack = false;
		}
	}
	Sys.println("read back: " + readBack);
}
