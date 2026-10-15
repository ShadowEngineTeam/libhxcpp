import cpp.vm.Gc;
import cpp.vm.WeakRef;

class Main {
	static var held:Array<Dynamic> = [5, true, "a", ""];

	static function main() {
		var names = ["int", "bool", "char", "empty"];
		var refs = [for (v in held) new WeakRef<Dynamic>(v)];
		var map = new haxe.ds.WeakMap<Dynamic, Int>();
		for (i in 0...held.length)
			map.set(held[i], i);
		Gc.run(true);
		Gc.run(true);
		for (i in 0...held.length)
			Sys.println(names[i] + " ref " + (refs[i].get() != null ? "kept" : "cleared") + ", key " + (map.exists(held[i]) ? "kept" : "cleared"));
	}
}
