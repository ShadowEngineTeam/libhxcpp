function main() {
	var s:String = untyped __cpp__('::String::create(u"a\\xd800" u"b", 3)');
	Sys.println(s.length);
	Sys.println(haxe.io.Bytes.ofString(s).toHex());
	Sys.println(StringTools.urlEncode(s));
	Sys.println(untyped __cpp__('(int)strlen({0}.utf8_str())', s));
}
