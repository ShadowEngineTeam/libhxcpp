#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#else
import sys.io.Process;
#end

// Gc.trace counted an object only where marking found it to be a container
// in a block, so it never counted a class whose instances are large
// allocations, or a class with no fields the collector follows, and a path
// it printed through a large object started at that object
class Main {
	#if macro
	// Enough object fields to make each instance a large allocation: the
	// inline allocator keeps objects of up to 16380 bytes in blocks
	static function manyFields():Array<Field> {
		var fields = Context.getBuildFields();
		for (i in 0...2500)
			fields.push({
				name: 'f$i',
				access: [APublic],
				kind: FVar(macro :Dynamic),
				pos: Context.currentPos()
			});
		return fields;
	}
	#else
	static var keep:Array<Dynamic>;

	static function child(mode:String):String {
		var process = new Process(Sys.programPath(), ["child", mode]);
		var output = process.stdout.readAll().toString();
		var code = process.exitCode();
		process.close();
		if (code != 0)
			Sys.stderr().writeString('mode=$mode exit=$code\n');
		return code == 0 ? output.split("\r\n").join("\n") : "exit " + code;
	}

	static function main() {
		var args = Sys.args();
		if (args.length == 2 && args[0] == "child") {
			var bigs = [for (i in 0...10) new Big()];
			bigs[3].f2499 = new Leaf();
			keep = [bigs, [for (i in 0...10) new Plain(i)], [for (i in 0...10) new Small()]];
			cpp.vm.Gc.run(true);
			if (args[1] == "count")
				Sys.print('${cpp.vm.Gc.trace(Big, false)} ${cpp.vm.Gc.trace(Plain, false)} ${cpp.vm.Gc.trace(Small, false)}');
			else
				Sys.print('traced ${cpp.vm.Gc.trace(Leaf, true)}');
			return;
		}
		var counts = child("count");
		if (counts != "10 10 10")
			Sys.stderr().writeString('counts: $counts\n');
		var parts = counts.split(" ");
		Sys.println("trace counts instances that are large allocations: " + (parts[0] == "10"));
		Sys.println("trace counts instances with no object fields: " + (parts[1] == "10"));
		Sys.println("trace counts small instances: " + (parts[2] == "10"));

		var path = child("path");
		// Main's static holds the large object that holds the Leaf
		var big = path.indexOf("Big.");
		var fromStatic = big > 0 && path.lastIndexOf("Main.", big) >= 0 && StringTools.endsWith(path, "traced 1");
		if (!fromStatic)
			Sys.stderr().writeString('path output:\n$path\n');
		Sys.println("a path printed through a large object starts at the static that holds it: " + fromStatic);
	}
	#end
}

#if !macro
@:build(Main.manyFields())
class Big {
	public function new() {}
}

class Plain {
	public var value:Int;
	public function new(value:Int) this.value = value;
}

class Small {
	public var next:Small;
	public function new() {}
}

class Leaf {
	public function new() {}
}
#end
