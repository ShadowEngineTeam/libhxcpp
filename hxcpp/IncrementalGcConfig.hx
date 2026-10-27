package hxcpp;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#end

class IncrementalGcConfig {
	public static macro function configure():haxe.macro.Expr {
		if (Context.defined("HXCPP_GC_INCREMENTAL") && !Context.defined("HXCPP_GC_INCREMENTAL_BARRIERS")) {
			for (name in ["HXCPP_GC_MOVING", "HXCPP_GC_DEBUG_ALWAYS_MOVE", "HXCPP_GC_NURSERY", "HXCPP_GC_GENERATIONAL", "HXCPP_GC_CONCURRENT", "scriptable", "cppia", "emscripten"]) {
				if (Context.defined(name))
					Context.fatalError('HXCPP_GC_INCREMENTAL does not currently support $name', Context.currentPos());
			}
			if (Std.parseInt(Context.definedValue("HXCPP_GC_DEBUG_LEVEL")) > 0)
				Context.fatalError("HXCPP_GC_INCREMENTAL does not support recursive GC debug levels", Context.currentPos());
			var version = Std.parseFloat(Context.definedValue("haxe_ver"));
			if (!Context.defined("cpp") || version < 4.3 || version >= 5)
				Context.fatalError("HXCPP_GC_INCREMENTAL currently requires native C++ with Haxe 4.3 or later in the 4.x series", Context.currentPos());
			// Request the existing generator's setter barriers. The runtime uses
			// ordinary allocation headers, not the generational nursery.
			Compiler.define("HXCPP_GC_GENERATIONAL");
			Compiler.define("HXCPP_GC_INCREMENTAL_BARRIERS");
		}
		return macro null;
	}
}
