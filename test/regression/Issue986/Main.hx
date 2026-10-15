function main() {
	var sb = new StringBuf();
	sb.add('{"a":[');
	for (i in 0...200000) {
		if (i > 0)
			sb.add(",");
		sb.add('{"k":"value$i","n":$i}');
	}
	sb.add("]}");
	var text = sb.toString();
	var parsed:Dynamic = haxe.Json.parse(text);
	var items:Array<Dynamic> = parsed.a;
	Sys.println(items.length);
	Sys.println(items[199999].k);
}
