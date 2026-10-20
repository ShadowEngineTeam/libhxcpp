function naive(hay:String, needle:String, from:Int):Int {
	if (from < 0)
		from = 0;
	var last = hay.length - needle.length;
	var i = from;
	while (i <= last) {
		if (hay.substr(i, needle.length) == needle)
			return i;
		i++;
	}
	return -1;
}

function main() {
	var rng = new haxe.ds.IntMap<Int>();
	var seed = 12345;
	function next(n:Int):Int {
		seed = (seed * 1103515245 + 12345) & 0x7fffffff;
		return seed % n;
	}
	var mismatches = 0, cases = 0;
	for (alphabet in ["ab", "abc", "a\u00E9", "aab\u00E9"]) {
		for (round in 0...600) {
			var hayLen = 100 + next(400);
			var hay = [for (i in 0...hayLen) alphabet.charAt(next(alphabet.length))].join("");
			var needle = if (next(2) == 0 && hayLen > 80) {
				var at = next(hayLen - 70);
				hay.substr(at, 32 + next(38));
			} else [for (i in 0...(32 + next(60))) alphabet.charAt(next(alphabet.length))].join("");
			var from = next(3) == 0 ? next(hayLen) : 0;
			cases++;
			if (hay.indexOf(needle, from) != naive(hay, needle, from))
				mismatches++;
		}
	}
	Sys.println('$cases cases, $mismatches mismatches');
	var big = [for (i in 0...1 << 20) "a"].join("");
	var needle = [for (i in 0...16383) "a"].join("") + "b";
	var t0 = haxe.Timer.stamp();
	var found = big.indexOf(needle);
	var ms = Math.round((haxe.Timer.stamp() - t0) * 1000);
	Sys.println("repetitive search found " + found);
	if (Sys.getEnv("SHOW_TIME") != null)
		Sys.println('repetitive 1 MB / 16 KB needle: $ms ms');
}
