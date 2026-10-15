function main() {
	Sys.println(StringTools.urlDecode("café%20bar") == "café bar");
	Sys.println(StringTools.urlDecode("ü%C3%A9+x") == "üé x");
	Sys.println(StringTools.urlDecode("\u{1F600}%21") == "\u{1F600}!");
	Sys.println(StringTools.urlDecode(StringTools.urlEncode("naïve 中")) == "naïve 中");
}
