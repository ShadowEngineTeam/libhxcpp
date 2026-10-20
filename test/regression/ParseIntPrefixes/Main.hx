function main() {
	for (s in ["", "-", "+", "0", "0x", "-0x", "+0x", "0x1", "-0x1F", "+0xff", "  0x10", "7x", "12", "-12", "x0"])
		Sys.println('"$s" -> ' + Std.parseInt(s));
	var long = "7x" + [for (i in 0...100000) "a"].join("");
	var t0 = haxe.Timer.stamp();
	var sum = 0;
	for (i in 0...500)
		sum += Std.parseInt(long);
	if (Sys.getEnv("SHOW_TIME") != null)
		Sys.println('500 parses of a 100k string: ${Math.round((haxe.Timer.stamp() - t0) * 1000)} ms ($sum)');
}
