package hxcpp.gc;

#if !cpp
#error "Incremental GC is available on the native cpp target"
#end

/** Optional scheduling hooks. Automatic collection needs no calls to this class. */
class Incremental {
	/** Perform a slice. Returns true if the collection still has work to do. */
	public static function step(budgetMs:Float = 0.5):Bool {
		return Native.step(budgetMs);
	}

	/** Set the automatic slice target and preferred spacing. Memory pressure can request earlier work. */
	public static function configure(budgetMs:Float = 0.5, intervalMs:Float = 1.0):Void {
		Native.configure(budgetMs, intervalMs);
	}

	public static function isActive():Bool {
		return Native.active();
	}

	/** Cumulative counters and end-to-end pause timings since process startup. */
	public static function getStats():Dynamic {
		return Native.stats();
	}
}

@:include("hx/GC.h")
private extern class Native {
	@:native("__hxcpp_gc_incremental_step") static function step(budgetMs:Float):Bool;
	@:native("__hxcpp_gc_incremental_configure") static function configure(budgetMs:Float, intervalMs:Float):Void;
	@:native("__hxcpp_gc_incremental_active") static function active():Bool;
	@:native("__hxcpp_gc_incremental_stats") static function stats():Dynamic;
}
