function main() {
	Sys.println(cpp.NativeString.parseInt("123"));
	Sys.println(cpp.NativeString.parseInt("  -42abc"));
	Sys.println(cpp.NativeString.parseInt("0x1F"));
	Sys.println(cpp.NativeString.parseInt("abc"));
	Sys.println(cpp.NativeString.parseSubstrInt("xx789yy", 2, 3));
	Sys.println(cpp.NativeString.parseSubstrInt("12345", -1, 3));
	Sys.println(cpp.NativeString.parseSubstrInt("12345", 1, 2147483647));
}
