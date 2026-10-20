class Main {
	static function main() {
		var a = ["d", "b", "a", "c"];
		a.sort((x, y) -> x < y ? -1 : (x > y ? 1 : 0));
		Sys.println("sorted: " + a.join(","));

		var b = ["x", "bb", "aa", "y", "cc", "dd"];
		b.sort((x, y) -> {
			cpp.vm.Gc.run(true);
			return y.length - x.length;
		});
		Sys.println("stable: " + b.join(","));

		var c:Array<String> = ["b", null, "a"];
		c.sort((x, y) -> x == null ? -1 : (y == null ? 1 : (x < y ? -1 : (x > y ? 1 : 0))));
		Sys.println("nulls first: " + c.map(s -> s == null ? "null" : s).join(","));

		var d = ["x", "z", "y"];
		var cmp:Dynamic = (x:Dynamic, y:Dynamic) -> Reflect.compare(y, x);
		d.sort(cmp);
		Sys.println("reverse: " + d.join(","));
	}
}
