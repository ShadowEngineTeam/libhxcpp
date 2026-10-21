class Script {
	static function main() {
		var a = [1, 2, 3];
		Sys.println("" + a.contains(1));
		var c:Dynamic = a.contains(9);
		Sys.println(Std.isOfType(c, Bool));
		var r:Dynamic = a.remove(2);
		Sys.println(Std.isOfType(r, Bool) + " " + r);
		var flags = [true, false, true];
		var p:Dynamic = flags.pop();
		Sys.println(Std.isOfType(p, Bool) + " " + p);
		// In an Array<Dynamic> literal the jit boxed these as Int
		var row:Array<Dynamic> = [a.contains(1), a.remove(3), flags[0], flags[1] = false];
		Sys.println(row + " " + [for (x in row) Std.isOfType(x, Bool)]);
	}
}
