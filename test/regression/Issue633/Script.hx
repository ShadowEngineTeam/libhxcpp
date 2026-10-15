class Script {
	static function main() {
		var a:Array<cpp.Float64> = [1.5, 2.5];
		a.push(3.0);
		Sys.println(a.length);
		Sys.println(a[0] + a[2]);
	}
}
