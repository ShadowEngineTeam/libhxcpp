package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class AnonMacro {
	static function fieldName(i:Int):String {
		return "f" + StringTools.lpad(Std.string(i), "0", 4);
	}

	/** An anonymous object literal with fields f0000, f0001, ... holding their index. **/
	public static macro function literal(count:Int):Expr {
		var fields:Array<ObjectField> = [for (i in 0...count) {field: fieldName(i), expr: macro $v{i}}];
		return {expr: EObjectDecl(fields), pos: Context.currentPos()};
	}

	/** The field names of literal(count) followed by as many names it lacks, all string literals. **/
	public static macro function names(count:Int):Expr {
		var names = [for (i in 0...count * 2) macro $v{fieldName(i)}];
		return macro $a{names};
	}
}

/**
	Reflect.field, hasField and setField on an anonymous object literal with
	field names that are string literals: a read and a write of a field it
	has, and a check for one it lacks.
**/
class AnonField extends Benchmark {
	final count:Int;
	final width:Int;
	final object:Dynamic;
	final names:Array<String>;

	public function new(name:String, count:Int, width:Int, object:Dynamic, names:Array<String>) {
		super(name, "field accesses", count * 3);
		this.count = count;
		this.width = width;
		this.object = object;
		this.names = names;
	}

	override public function run():Int {
		var sum = 0;
		var o = object;
		for (i in 0...count) {
			var name = names[(i * 37) % width];
			var v:Int = Reflect.field(o, name);
			Reflect.setField(o, name, v + 1);
			if (Reflect.hasField(o, names[width + (i % width)]))
				sum++;
			sum = (sum + v) | 0;
		}
		return sum;
	}
}

class AnonFieldSmall extends AnonField {
	public function new() {
		super("anon_field", 4000000, 16, AnonMacro.literal(16), AnonMacro.names(16));
	}
}

class AnonFieldWide extends AnonField {
	public function new() {
		super("anon_field_wide", 1000000, 256, AnonMacro.literal(256), AnonMacro.names(256));
	}
}
