// A class with two @:nativeGen interfaces holds its second interface at an
// offset inside the object. HX_REGISTER_VTABLE_OFFSET cast a null pointer to
// find that offset, which stays null, so it registered 0 and the collector did
// not take a pointer to the second interface as a reference to the object. An
// object held only through that interface was freed, and calling through it
// crashed. Converting an object to such an interface also took the object's
// address as the interface pointer, which crashed without any collection, and
// the macro failed to compile with MSVC. HaxeFoundation/hxcpp#1380
@:nativeGen
interface IFirst {
	public function first():Int;
}

@:nativeGen
interface ISecond {
	public function second():Int;
}

class Both implements IFirst implements ISecond {
	public var data:Array<Int>;

	public function new(n:Int) {
		data = [for (i in 0...n) i];
	}

	public function first():Int
		return data.length;

	public function second():Int {
		var sum = 0;
		for (v in data)
			sum += v;
		return sum;
	}
}

class Main {
	// Only the interface pointer leaves this function
	@:analyzer(ignore)
	static function makeSecond(n:Int):ISecond {
		return new Both(n);
	}

	@:analyzer(ignore)
	static function makeFirst(n:Int):IFirst {
		return new Both(n);
	}

	// Through Dynamic, which took the object's address as the interface pointer
	@:analyzer(ignore)
	static function makeSecondFromDynamic(n:Int):ISecond {
		var d:Dynamic = new Both(n);
		return d;
	}

	// A @:nativeGen interface is a native pointer, not a Haxe object, so the
	// collector finds it only by scanning the stack: it is kept in locals here
	static function main() {
		var second:ISecond = makeSecond(100);
		var first:IFirst = makeFirst(100);
		var fromDynamic:ISecond = makeSecondFromDynamic(100);
		for (round in 0...5) {
			var garbage = [for (j in 0...20000) [j, j]];
			cpp.vm.Gc.run(true);
		}
		var wrong = 0;
		if (second.second() != 4950)
			wrong++;
		if (first.first() != 100)
			wrong++;
		if (fromDynamic.second() != 4950)
			wrong++;
		Sys.println('objects held through a native interface: $wrong wrong');
	}
}
