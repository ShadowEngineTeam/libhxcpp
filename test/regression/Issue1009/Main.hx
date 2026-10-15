function main() {
	var b:Dynamic = true;
	var i:Dynamic = 1;
	Sys.println(b == i);
	Sys.println(b != i);
	var f:Dynamic = false;
	var z:Dynamic = 0;
	Sys.println(f == z);
	var a:Any = true;
	var j:Any = 1;
	Sys.println(a == j);
	var t:Dynamic = true;
	Sys.println(b == t);
	Sys.println(b != f);
	var one:Dynamic = 1.0;
	Sys.println(b == one);
	var wide:Dynamic = haxe.Int64.ofInt(1);
	Sys.println(b == wide);
	var mixed:Array<Dynamic> = [1, true];
	Sys.println(mixed.indexOf(true));
}
