import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

// A map that held itself formatted itself again for every level until the
// native stack overflowed. Past 5 nested maps a map now formats as "...", as
// arrays and anonymous objects do (libhxcpp #343).
class Thrower {
	public function new() {}

	public function toString():String
		throw "formatter failed";
}

class Main {
	static function main() {
		var smap = new StringMap<Dynamic>();
		smap.set("self", smap);
		Sys.println('StringMap holding itself as a value: ${Std.string(smap) == "[self => [self => [self => [self => [self => ...]]]]]"}');

		var imap = new IntMap<Dynamic>();
		imap.set(1, imap);
		Sys.println('IntMap holding itself as a value: ${Std.string(imap) == "[1 => [1 => [1 => [1 => [1 => ...]]]]]"}');

		var omap = new ObjectMap<Dynamic, Dynamic>();
		omap.set(omap, 1);
		Sys.println('ObjectMap holding itself as a key: ${Std.string(omap) == "[[[[[... => 1] => 1] => 1] => 1] => 1]"}');

		var mixed = new StringMap<Dynamic>();
		mixed.set("a", [{m: mixed}]);
		Sys.println('cycle through an array and an anonymous object: ${Std.string(mixed).length > 0}');

		// A formatter that throws gives back the depth it took
		var throwing = new StringMap<Dynamic>();
		throwing.set("t", new Thrower());
		var caught = 0;
		for (i in 0...32)
			try {
				Std.string(throwing);
			} catch (e:String) {
				caught++;
			}
		Sys.println('throwing value formatter is caught each time: ${caught == 32}');

		var nested = new StringMap<Dynamic>();
		var inner = new IntMap<String>();
		inner.set(7, "seven");
		nested.set("inner", inner);
		var deep:Dynamic = nested;
		for (i in 0...3) {
			var outer = new StringMap<Dynamic>();
			outer.set("m", deep);
			deep = outer;
		}
		Sys.println('formatting still works after the throws: ${Std.string(nested) == "[inner => [7 => seven]]"}');
		Sys.println('five nested maps format in full: ${Std.string(deep) == "[m => [m => [m => [inner => [7 => seven]]]]]"}');
	}
}
