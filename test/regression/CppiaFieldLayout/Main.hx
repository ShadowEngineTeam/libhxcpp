class Main {
	static function bytesOf(census:Array<Dynamic>, name:String):Float {
		for (row in census)
			if (row.name == name)
				return row.bytes / row.count;
		return -1;
	}

	// Script fields are aligned to their types. Declared with Ints between
	// pointers, each Int was followed by a gap, so the object was larger than
	// the same fields grouped by type.
	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			var module = cpp.cppia.Module.fromData(bytes.getData());
			module.boot();
			module.run();
			var census:Array<Dynamic> = untyped __global__.__hxcpp_gc_census();
			var mixed = bytesOf(census, "Mixed");
			var grouped = bytesOf(census, "Grouped");
			var sums = 0;
			for (o in (Reflect.field(module.resolveClass("Script"), "mixed") : Array<Dynamic>))
				sums += o.sum();
			for (o in (Reflect.field(module.resolveClass("Script"), "grouped") : Array<Dynamic>))
				sums += o.sum();
			Sys.println('jit $jit: counted: ${mixed > 0 && grouped > 0}');
			Sys.println('jit $jit: field order costs no space: ${mixed == grouped}');
			Sys.println('jit $jit: fields read back: ${sums == 2 * (1000 * 1000 + 2000)}');
			untyped module.release();
		}
	}
}
