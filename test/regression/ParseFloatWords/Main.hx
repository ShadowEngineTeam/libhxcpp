function main() {
	for (s in ["info", "inferior", "nan", "inf", "Infinity", "-Infinity", "0x10", " -0x1p3", " 1.5e2x", ".5", "+7", "-.25", "", "abc", "."])
		Sys.println(s + " -> " + Std.parseFloat(s));
	Sys.println(Std.parseFloat(Std.string(Math.NEGATIVE_INFINITY)) == Math.NEGATIVE_INFINITY);
	Sys.println(cpp.NativeString.parseSubstrFloat("xxinfo", 2, 4));
	Sys.println(cpp.NativeString.parseSubstrFloat("x2.5x", 1, 3));
}
