// Compiled to corpus/cppia/script.cppia, the cppia target's seed:
// haxe -cp seeds -main Script --cppia corpus/cppia/script.cppia
class Script {
	static var counter = 0;

	var name:String;

	function new(name:String) {
		this.name = name;
	}

	function greet():String {
		counter++;
		return 'hello $name $counter';
	}

	static function main() {
		var list = [for (i in 0...3) new Script("s" + i)];
		var map = new Map<String, Int>();
		for (s in list)
			map.set(s.greet(), s.name.length);
		trace(Lambda.count(map));
		switch (Std.random(2)) {
			case 0:
				throw "zero";
			default:
		}
	}
}
