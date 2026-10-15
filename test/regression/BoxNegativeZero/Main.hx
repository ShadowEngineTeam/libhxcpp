function main() {
	var z = Std.parseFloat("-0");
	var d:Dynamic = z;
	Sys.println(1 / (d : Float));
	Sys.println(Type.typeof(d));
	var p:Dynamic = Std.parseFloat("0");
	Sys.println(Type.typeof(p));
	Sys.println(d == p);
}
