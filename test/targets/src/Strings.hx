using StringTools;

// String behaviour that every Haxe target should agree on
class Strings {
	static function p(label:String, value:Dynamic)
		Out.println(label + ": " + Std.string(value));

	public static function run() {
		var s = "héllo wörld 😀 ok";
		p("length", s.length);
		p("charAt", [for (i in [0, 1, 12, 13, 14, 99, -1]) s.charAt(i)].join("|"));
		p("charCodeAt", [for (i in [0, 1, 12, 13, -1, 99]) s.charCodeAt(i)]);
		p("indexOf", [s.indexOf("o"), s.indexOf("o", 5), s.indexOf("o", -5), s.indexOf("o", 99), s.indexOf(""), s.indexOf("", 99), s.indexOf("😀")]);
		p("lastIndexOf", [s.lastIndexOf("o"), s.lastIndexOf("o", 5), s.lastIndexOf("o", -5), s.lastIndexOf("o", 99), s.lastIndexOf(""), s.lastIndexOf("", 3)]);
		p("substr", [s.substr(2), s.substr(2, 3), s.substr(-3), s.substr(-3, 2), s.substr(99), s.substr(0, 0)].join("|"));
		p("substring", [s.substring(2, 5), s.substring(5, 2), s.substring(-3, 2), s.substring(2, 99), s.substring(99, 2)].join("|"));
		p("split", "a,b,,c,".split(","));
		p("split empty", "abc".split(""));
		p("split none", "abc".split(";"));
		p("case", [s.toUpperCase(), "ÀÉÎ ß".toLowerCase(), "istanbul".toUpperCase()].join("|"));
		p("fromCharCode", [String.fromCharCode(65), String.fromCharCode(233), String.fromCharCode(0x1F600)].join("|"));
		p("compare", ["a" < "b", "B" < "a", "é" > "z", "a" == "a", "ab" < "abc", "" < "a"]);
		p("concat", "a" + 1 + 2.5 + true + null);
		p("trim", ["  a b  ".trim(), " \t\na\r\n ".ltrim(), "x  ".rtrim()].join("|"));
		p("replace", ["aaa".replace("a", "bb"), "abcabc".replace("bc", ""), "x".replace("", "-")].join("|"));
		p("pad", ["5".lpad("0", 3), "5".rpad("ab", 4), "long".lpad("0", 2)].join("|"));
		p("startsWith", ["hello".startsWith("he"), "hello".endsWith("lo"), "".startsWith(""), "a".endsWith("ab")]);
		p("contains", ["hello".contains("ll"), "hello".contains("")]);
		p("hex", [StringTools.hex(255), StringTools.hex(255, 4), StringTools.hex(-1)].join("|"));
		p("urlEncode", "a b&c=é/😀".urlEncode());
		p("urlDecode", "a%20b%26c%3D%C3%A9%2F%F0%9F%98%80+x".urlDecode());
		p("htmlEscape", "<a href=\"x\">&'</a>".htmlEscape(true));
		p("isSpace", [" \t\n".isSpace(0), "a".isSpace(0)]);
		p("iterator", [for (c in "aé😀") c]);
		p("keyValueIterator", [for (i => c in "aé") '$i:$c']);
		var b = new StringBuf();
		b.add("x");
		b.addChar(0xE9);
		b.addSub("abcdef", 2, 3);
		b.add(1.5);
		b.add(null);
		p("StringBuf", b.toString() + " " + b.length);
		p("Std.string", [Std.string(null), Std.string(true), Std.string([1, 2]), Std.string([[1], []])].join("|"));
		var d:Dynamic = "abc";
		p("dynamic compare", [d == "abc", "abc" == d, d < "abd", d.length]);
	}
}
