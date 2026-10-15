import cpp.vm.WeakRef;

class Main {
	static function install(depth:Int):WeakRef<Dynamic> {
		if (depth > 0)
			return install(depth - 1);
		var prefix = "handled " + Std.string(Std.random(1) + 1);
		var handler:Dynamic = function(message:String) throw prefix + " " + message;
		untyped __global__.__hxcpp_set_critical_error_handler(handler);
		return new WeakRef(handler);
	}

	static function main() {
		var weak = install(10);
		for (round in 0...5) {
			cpp.vm.Gc.run(true);
			var junk = [for (i in 0...100000) "x" + i];
		}
		Sys.println(weak.get() != null ? "handler alive" : "handler collected");
		try {
			untyped __cpp__("::hx::CriticalError(HX_CSTRING(\"boom\"), false)");
			Sys.println("returned");
		} catch (e:Dynamic) {
			Sys.println(e);
		}
	}
}
