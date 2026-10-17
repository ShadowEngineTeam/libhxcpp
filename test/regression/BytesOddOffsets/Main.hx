import haxe.io.Bytes;
import haxe.io.FPHelper;

// Bytes, Memory and FPHelper read and wrote 16, 32 and 64-bit values through
// cast pointers, which is undefined at an odd offset and traps on CPUs without
// unaligned access. Every width is written and read back at offsets 0 to 7,
// and the byte order checked; UBSan reports a misaligned access if it returns.
function hex(b:Bytes, pos:Int, len:Int):String {
	var s = "";
	for (i in pos...pos + len)
		s += StringTools.hex(b.get(i), 2);
	return s;
}

function main() {
	var b = Bytes.alloc(16);
	var d = b.getData();
	var wrong = 0;
	for (pos in 0...8) {
		b.fill(0, 16, 0);
		b.setFloat(pos, 1.25);
		if (b.getFloat(pos) != 1.25) wrong++;
		b.setDouble(pos, -2.5e300);
		if (b.getDouble(pos) != -2.5e300) wrong++;
		untyped __global__.__hxcpp_memory_set_i16(d, pos, -2);
		if (untyped __global__.__hxcpp_memory_get_i16(d, pos) != -2) wrong++;
		if (untyped __global__.__hxcpp_memory_get_ui16(d, pos) != 0xfffe) wrong++;
		untyped __global__.__hxcpp_memory_set_i32(d, pos, 0x12345678);
		if (untyped __global__.__hxcpp_memory_get_i32(d, pos) != 0x12345678) wrong++;
		if (hex(b, pos, 4) != "78563412") wrong++;
		untyped __global__.__hxcpp_memory_set_ui32(d, pos, 0xfedcba98);
		if (untyped __global__.__hxcpp_memory_get_ui32(d, pos) != 0xfedcba98) wrong++;
		untyped __global__.__hxcpp_memory_set_f32(d, pos, 0.5);
		if (untyped __global__.__hxcpp_memory_get_f32(d, pos) != 0.5) wrong++;
	}
	Sys.println('odd offsets: $wrong wrong');
	b.setFloat(1, 1.0);
	Sys.println("float 1.0 at 1: " + hex(b, 1, 4));
	b.setDouble(3, 1.0);
	Sys.println("double 1.0 at 3: " + hex(b, 3, 8));
	Sys.println("float bits of 1.0: " + StringTools.hex(FPHelper.floatToI32(1.0), 8));
	Sys.println("i32 to float: " + FPHelper.i32ToFloat(0x40490fdb));
	var bits = FPHelper.doubleToI64(1.0);
	Sys.println("double bits of 1.0: " + StringTools.hex(bits.high, 8) + StringTools.hex(bits.low, 8));
	Sys.println("i64 to double: " + FPHelper.i64ToDouble(0, 0x40000000));
}
