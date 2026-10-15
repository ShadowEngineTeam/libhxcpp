class Script {
	static function main() {
		var a = new Array<cpp.Float32>();
		a.push(1.5);
		a.push(2.5);
		a[2] = 3.25;
		a[0] = a[0] + a[1];
		Sys.println(a[0] + " " + a[1] + " " + a[2] + " " + a.length);
		var literal:Array<cpp.Float32> = [0.5, 0.25];
		Sys.println(literal[0] + literal[1]);
		var sum = 0.0;
		for (v in a)
			sum += v;
		Sys.println(sum);
		a[1] += 1.25;
		var boxed:Dynamic = a[1];
		var popped = a.pop();
		Sys.println(boxed + " " + popped + " " + a.length);
	}
}
