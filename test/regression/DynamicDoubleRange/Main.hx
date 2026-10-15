function main() {
	for (v in [Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NaN, 1e300, -1e300, 2147483648.0, -2147483649.0, 4294967296.5]) {
		var d:Dynamic = v;
		var back:Float = d;
		Sys.println(Std.isOfType(d, Int) + " " + (Math.isNaN(v) ? Math.isNaN(back) : back == v));
	}
}
