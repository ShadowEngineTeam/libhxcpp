function main() {
	var s = "ab" + Std.string(Sys.time() > 0);
	Sys.println(haxe.Utf8.charCodeAt(s, -1));
	Sys.println(haxe.Utf8.charCodeAt("ab", -1));
	Sys.println(Math.isNaN(cpp.NativeString.parseSubstrFloat("12345", -1, 3)));
	Sys.println(Math.isNaN(cpp.NativeString.parseSubstrFloat("12345", 1, 2147483647)));
	Sys.println(cpp.NativeString.parseSubstrFloat("12345", 1, 2));
}
