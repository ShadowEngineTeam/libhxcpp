// Number behaviour that every Haxe target should agree on. Floats are printed
// only where their text is the same on every target: Haxe leaves the format
// of very large and very small Floats to each one.
class Numbers {
	static function p(label:String, value:Dynamic)
		Out.println(label + ": " + Std.string(value));

	public static function run() {
		var big = 0x7fffffff;
		p("int overflow", [big + 1, big * 2, -big - 2, 0x10000 * 0x10000, 46341 * 46341]);
		p("int ops", [7 % 3, -7 % 3, 7 % -3, -7 >> 1, -7 >>> 28, 1 << 31, 1 << 32, 5 ^ 3, ~5]);
		p("int division", [7 / 2, -7 / 2, 1 / 4]);
		p("Std.int", [Std.int(2.9), Std.int(-2.9), Std.int(0.5), Std.int(-0.5)]);
		p("parseInt", [Std.parseInt("42"), Std.parseInt(" 42"), Std.parseInt("42abc"), Std.parseInt("-17"), Std.parseInt("+5"), Std.parseInt("0x1F"), Std.parseInt("abc"), Std.parseInt(""), Std.parseInt("3.9")]);
		p("parseFloat", [Std.parseFloat("1.5"), Std.parseFloat(" 2.25 "), Std.parseFloat("1e3"), Std.parseFloat("-0.5x"), Std.parseFloat(".5"), Std.parseFloat("5."), Std.parseFloat("abc"), Std.parseFloat("")]);
		p("float text", [0.1 + 0.2, 1 / 3, 100.0, 1.5e-3, 123456.789, 1e14]);
		p("special", [Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.isNaN(0 / 0), Math.isFinite(1 / 0)]);
		p("rounding", [Math.round(2.5), Math.round(-2.5), Math.round(-0.5), Math.floor(-1.5), Math.ceil(-1.5), Math.fround(2.5), Math.ffloor(-0.5)]);
		p("math", [Math.abs(-3), Math.min(1, 2), Math.max(-1.5, -2), Math.sqrt(16), Math.pow(2, 10), Math.floor(Math.exp(1) * 1000)]);
		p("min max nan", [Math.isNaN(Math.min(1, Math.NaN)), Math.isNaN(Math.max(Math.NaN, 1))]);
		var z:Float = -0.0;
		var dz:Dynamic = z;
		p("negative zero", [1 / z, 1 / (dz : Float), z == 0]);
		var f:Dynamic = 3.0;
		var i:Dynamic = 3;
		p("dynamic numbers", [f == i, f + i, Std.isOfType(f, Int), Std.isOfType(i, Float), Std.isOfType(1.5, Int)]);
		p("int as float", [(big : Float) + 1, 1.0 * big * 2]);
		var u:UInt = 0xffffffff;
		p("UInt", [u, u + 1, u > 0, (u : Float)]);
		var a = haxe.Int64.make(1, 2);
		var b = haxe.Int64.ofInt(-5);
		p("Int64", [haxe.Int64.toStr(a), haxe.Int64.toStr(a * b), haxe.Int64.toStr(a / haxe.Int64.ofInt(3)), haxe.Int64.toStr(haxe.Int64.parseString("-9223372036854775808")), haxe.Int64.toStr(haxe.Int64.ofInt(-1) >>> 60)]);
		var i32:haxe.Int32 = big;
		p("Int32 wrap", [i32 + 1]);
	}
}
