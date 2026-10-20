function main() {
	var small:Dynamic = {x: 1};
	var expected = Std.string(small);
	var inside = new sys.thread.Lock();
	var resume = new sys.thread.Lock();
	var finished = new sys.thread.Lock();
	var leaf:Dynamic = {
		toString: () -> {
			inside.release();
			resume.wait(5);
			return "leaf";
		}
	};
	var deep:Dynamic = {a: {b: {c: {d: leaf}}}};
	sys.thread.Thread.create(() -> {
		Std.string(deep);
		finished.release();
	});
	var reached = inside.wait(5);
	var during = Std.string(small);
	resume.release();
	finished.wait(5);
	Sys.println("worker reached the leaf: " + reached);
	Sys.println("other thread keeps its string: " + (during == expected));
	var throwing:Dynamic = {toString: () -> throw "no"};
	for (i in 0...6)
		try Std.string(throwing) catch (_:Dynamic) {}
	Sys.println("after throws: " + (Std.string(small) == expected));
}
