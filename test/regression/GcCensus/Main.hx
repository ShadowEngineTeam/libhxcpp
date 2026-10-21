class Small {
	public var a:Int;

	public function new(a:Int)
		this.a = a;
}

class Leaky {
	public var next:Leaky;

	public function new(next:Leaky)
		this.next = next;
}

class Flat {
	public var a:Int;

	public function new(a:Int)
		this.a = a;
}

class Main {
	static var held:Array<Flat>;

	static function rowFor(census:Array<Dynamic>, name:String):Dynamic {
		for (row in census)
			if (row.name == name)
				return row;
		return null;
	}

	// __hxcpp_gc_census counts the live objects of each class in a release build,
	// where Gc.trace needs a debug build.
	static function main() {
		var keep = [for (i in 0...20000) new Small(i)];
		var chain:Leaky = null;
		for (i in 0...300)
			chain = new Leaky(chain);
		for (i in 0...100000)
			new Small(i);

		for (round in 0...2) {
			var census:Array<Dynamic> = untyped __global__.__hxcpp_gc_census();
			var small:Dynamic = rowFor(census, "Small");
			var leaky:Dynamic = rowFor(census, "Leaky");
			if (small == null || leaky == null) {
				Sys.println("census " + round + " is missing a class: " + [for (row in census) row.name + " " + row.count].join(", "));
				continue;
			}
			var sorted = true;
			for (i in 1...census.length)
				if (census[i].bytes > census[i - 1].bytes)
					sorted = false;
			Sys.println("census " + round + ": Small " + small.count + ", Leaky " + leaky.count + ", bytes counted " + (small.bytes >= small.count * 8)
				+ ", most bytes first " + sorted);
		}

		// An object with no pointer fields looks like raw memory on the stack, so
		// the last one a loop made, still in a stack slot, was marked as memory
		// there before the array reached it, and went uncounted
		held = [for (i in 0...1000) new Flat(i)];
		var census:Array<Dynamic> = untyped __global__.__hxcpp_gc_census();
		var flat:Dynamic = rowFor(census, "Flat");
		Sys.println("held " + (flat == null ? 0 : flat.count));
		Sys.println("kept " + keep.length + " " + held.length + " " + (chain.next != null));
	}
}
