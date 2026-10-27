import cpp.vm.Gc;

// Std.string on an enum formatted each parameter to a String and copied it
// into its parent's, recursing once per level: O(n^2) copying and native
// stack for a chain n deep, which overflowed at a million levels. Enums are
// now formatted with one builder and a stack of their own (libhxcpp #328).
enum Chain {
	End;
	Link(next:Chain);
}

enum Shape {
	Empty;
	Pair(a:Shape, b:Shape);
	Leaf(i:Int, f:Float, s:String, b:Bool, d:Dynamic);
	Named(o:Labelled);
}

class Labelled {
	public static var calls:Array<String> = [];

	final name:String;

	public function new(name:String)
		this.name = name;

	public function toString():String {
		calls.push(name);
		// Collects in the middle of formatting the enums around this value
		var junk = [for (i in 0...1000) [i]];
		Gc.run(true);
		Gc.compact();
		return '<$name>';
	}
}

class Main {
	static function chain(depth:Int):Chain {
		var value = End;
		for (i in 0...depth)
			value = Link(value);
		return value;
	}

	static function expectedChain(depth:Int):String {
		var b = new StringBuf();
		for (i in 0...depth)
			b.add("Link(");
		b.add("End");
		for (i in 0...depth)
			b.add(")");
		return b.toString();
	}

	static function main() {
		Sys.println('chain 2,048 deep formats completely: ${Std.string(chain(2048)) == expectedChain(2048)}');
		Sys.println('chain 1,000,000 deep formats completely: ${Std.string(chain(1000000)) == expectedChain(1000000)}');

		var leaf = Leaf(-3, 1.5, "λ✓", true, null);
		Sys.println('basic, Unicode and null parameters: ${Std.string(leaf) == "Leaf(-3,1.5,λ✓,true,null)"}');
		Sys.println('null string and array parameters: ${Std.string(Leaf(0, 0, null, false, [1, 2])) == "Leaf(0,0,null,false,[1,2])"}');
		var shared = Pair(leaf, Empty);
		Sys.println('shared children at each occurrence: ${Std.string(Pair(shared, Pair(shared, Empty))) == "Pair(Pair(Leaf(-3,1.5,λ✓,true,null),Empty),Pair(Pair(Leaf(-3,1.5,λ✓,true,null),Empty),Empty))"}');

		var value = Pair(Named(new Labelled("a")), Pair(Named(new Labelled("b")), Named(new Labelled("c"))));
		Sys.println('custom toString that collects: ${Std.string(value) == "Pair(Named(<a>),Pair(Named(<b>),Named(<c>)))"}');
		Sys.println('custom toString called once each, in order: ${Labelled.calls.join(",") == "a,b,c"}');

		Sys.println('constructor without parameters: ${Std.string(Empty) == "Empty"}');
		var d:Dynamic = Link(Link(End));
		Sys.println('enum through Dynamic: ${'$d' == "Link(Link(End))"}');
	}
}
