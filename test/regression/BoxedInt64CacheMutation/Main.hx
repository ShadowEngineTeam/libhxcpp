class Main {
	static function main() {
		var first:Dynamic=haxe.Int64.make(0,7);
		var independent:Dynamic=haxe.Int64.make(0,7);
		var field=#if cpp "lo" #else "low" #end;
		try Reflect.setField(first,field,9) catch(e:Dynamic) {}
		
		var untouched:haxe.Int64=cast independent;
		var createdAfter:Dynamic=haxe.Int64.make(0,7);
		var fresh:haxe.Int64=cast createdAfter;
		// Restore the cached box before reporting so this probe does not
		// leave the shared constant changed for the rest of the process.
		try Reflect.setField(first,field,7) catch(e:Dynamic) {}
		Sys.println("independent boxed value unchanged: "+(untouched==haxe.Int64.make(0,7)));
		Sys.println("later boxing keeps original value: "+(fresh==haxe.Int64.make(0,7)));
	}
}