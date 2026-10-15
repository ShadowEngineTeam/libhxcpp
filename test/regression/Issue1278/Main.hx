function main() {
	var small:Dynamic = haxe.Int64.ofInt(5);
	var big:Dynamic = haxe.Int64.make(1, 0);
	Sys.println(Std.string(Type.typeof(big)));
	Sys.println(Std.string(Type.typeof(small)));
}
