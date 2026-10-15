function main() {
	var s = "a\u{1F600}b";
	Sys.println(s.length);
	Sys.println(s.substr(0, 2) + s.substr(2) == s);
	Sys.println(s.substring(0, 2) + s.substring(2) == s);
	Sys.println(s.substr(0, 2).charCodeAt(1) == 0xD83D);
	Sys.println(s.substr(2).charCodeAt(0) == 0xDE00);
	Sys.println(s.substr(1, 1).charCodeAt(0) == 0xD83D);
	Sys.println(haxe.io.Bytes.ofString(s.substr(0, 2)).toHex());
}
