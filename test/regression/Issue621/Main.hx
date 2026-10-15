function value(?d:Int = -2147483648):Int {
	return d;
}

function main() {
	Sys.println(value());
	Sys.println(value(5));
	var size:Dynamic = untyped __cpp__("::Dynamic((size_t)7)");
	Sys.println(size);
	var wide:Dynamic = untyped __cpp__("::Dynamic((long)-2147483648)");
	Sys.println(wide);
}
