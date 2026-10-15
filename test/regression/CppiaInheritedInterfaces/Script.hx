interface IFoo {
	function foo():Int;
}

interface IBar extends IFoo {
	function bar():Int;
}

class A implements IBar {
	public function new() {}

	public function foo()
		return 1;

	public function bar()
		return 2;
}

class B extends A {}

class Script {
	static function main() {
		var a:Dynamic = new A();
		var b:Dynamic = new B();
		Sys.println(Std.isOfType(a, IFoo) + " " + Std.isOfType(a, IBar));
		Sys.println(Std.isOfType(b, IFoo) + " " + Std.isOfType(b, IBar));
		Sys.println(cast(a, IFoo).foo());
		try {
			throw b;
		} catch (e:IFoo) {
			Sys.println("caught " + e.foo());
		} catch (e:Dynamic) {
			Sys.println("missed");
		}
	}
}
