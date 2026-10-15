function main() {
	var min:Int = Std.parseInt("-2147483648");
	var minusOne:Int = Std.parseInt("-1");
	Sys.println(min % minusOne);
	Sys.println(7 % minusOne);
	Sys.println(min % Std.parseInt("3"));
}
