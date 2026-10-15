function main() {
	var args:Array<Any> = [];
	args.push(haxe.Int64.parseString("9138745278763343734"));
	args.push(0.24332);
	Sys.println(args[0] == haxe.Int64.parseString("9138745278763343734"));
	Sys.println(Std.string(args[0]));
}
