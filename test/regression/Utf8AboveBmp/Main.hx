function main() {
	var u = new haxe.Utf8();
	for (c in [0x41, 0x1F600, 0xE9, 0x10FFFF])
		u.addChar(c);
	Sys.println(u.toString() == "A\u{1F600}\u00E9\u{10FFFF}");
	var one = new haxe.Utf8();
	one.addChar(0x1F600);
	Sys.println(one.toString() == "\u{1F600}");
	var bad = new haxe.Utf8();
	for (c in [0xD800, 0x110000, 0x42])
		bad.addChar(c);
	Sys.println(bad.toString() == "\u{FFFD}\u{FFFD}B");
}
