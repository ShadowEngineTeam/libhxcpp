function build(keys:Array<Int>):Float {
	var best = 1e9;
	for (round in 0...3) {
		var t0 = haxe.Timer.stamp();
		var m = new Map<Int, Int>();
		for (k in keys)
			m.set(k, k);
		for (k in keys)
			if (m.get(k) != k)
				throw "lost " + k;
		best = Math.min(best, haxe.Timer.stamp() - t0);
	}
	return best;
}

function main() {
	var dense = [for (i in 0...512 * 512) i];
	var packed = [for (x in 0...512) for (y in 0...512) (x << 16) | y];
	var ratio = build(packed) / build(dense);
	Sys.println(ratio < 8 ? "ok" : "packed keys are " + Math.round(ratio) + "x slower");
}
