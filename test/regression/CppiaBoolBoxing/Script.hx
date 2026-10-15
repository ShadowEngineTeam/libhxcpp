interface Contains<T> {
	function contains(x:T):Bool;
}

class Holder<T> implements Contains<T> {
	public var flag:Bool = true;
	public var other:Bool;
	public static var staticFlag:Bool = true;

	public function new() {
		other = true;
	}

	public function contains(x:T):Bool {
		return true;
	}

	public function get():Bool {
		return flag;
	}
}

enum Wrapped {
	Flag(b:Bool);
}

class Script {
	static function same<S>(a:S, b:S, and:Bool->Bool->S):S {
		return and(true, true);
	}

	static function both<S>(x:Bool, y:Bool):Dynamic {
		return x && y;
	}

	static function generic<S>(v:Bool):S {
		return cast (v && true);
	}

	static function id<T>(x:T):T {
		return x;
	}

	static function check(name:String, d:Dynamic) {
		Sys.println(name + " " + Std.isOfType(d, Bool) + " " + (d == true));
	}

	static function main() {
		var h = new Holder<Int>();
		var c:Contains<Int> = h;
		check("interface", c.contains(1));
		check("method", h.contains(1));
		check("field", h.flag);
		check("assigned", h.other);
		check("static", Holder.staticFlag);
		check("reflect", Reflect.field(h, "flag"));
		check("getter", h.get());
		check("generic", id(true));
		var local = true;
		check("local", local);
		var arr = [true];
		check("array", arr[0]);
		var f:Void->Bool = h.get;
		check("closure", f());
		var anon = {b: true};
		check("anon", anon.b);
		check("enum", switch (Flag(true)) { case Flag(b): (b:Dynamic); });
		var fromEnum:Dynamic = Type.enumParameters(Flag(true))[0];
		check("enumparam", fromEnum);
		check("and", both(true, true));
		check("genericand", generic(true));
		check("json", haxe.Json.stringify(Reflect.field(h, "flag")) == "true");
	}
}
