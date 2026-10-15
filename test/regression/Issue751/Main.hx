private interface Interface {
	var foo(get, null):Bool;
}

function main() {
	var s:String = "";
	var c = try cast(s, Interface) catch (e:Dynamic) null;
	Sys.println(c == null);
}
