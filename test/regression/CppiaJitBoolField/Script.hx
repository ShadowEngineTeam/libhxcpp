typedef Entry = {var kind:String; @:optional var failed:Bool;}

class Script {
	static function setFlag(e:Entry, flag:Bool) {
		e.failed = flag;
	}

	static function main() {
		// The jit boxed Bools stored in dynamic fields as the Int 1
		var a:Entry = {kind: "a"};
		a.failed = true;
		Sys.println((a.failed == true) + " (" + a.failed + ")");
		var dyn:Dynamic = {kind: "b"};
		dyn.failed = true;
		Sys.println((dyn.failed == true) + " (" + dyn.failed + ")");
		var f:{?x:Bool} = {};
		f.x = 2 > 1;
		Sys.println((f.x == true) + " (" + f.x + ")");
		var g:Entry = {kind: "g"};
		setFlag(g, false);
		var boxed:Dynamic = g.failed;
		Sys.println(Std.isOfType(boxed, Bool) + " (" + g.failed + ")");
		var unset:Entry = {kind: "u"};
		Sys.println(unset.failed);
		// The assignment's own value, a literal and Reflect box it too
		var assigned:Dynamic = (dyn.other = 3 > 1);
		Sys.println(Std.isOfType(assigned, Bool) + " (" + assigned + ")");
		var lit:Dynamic = {flag: 2 > 1, fixed: false};
		Sys.println(Std.isOfType(lit.flag, Bool) + " " + Std.isOfType(lit.fixed, Bool) + " (" + lit.flag + " " + lit.fixed + ")");
		var r:Dynamic = {};
		Reflect.setField(r, "x", 1 < 2);
		Sys.println(Std.isOfType(r.x, Bool) + " (" + r.x + ")");
	}
}
