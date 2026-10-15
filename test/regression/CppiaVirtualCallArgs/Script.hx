interface Recorder {
	function record(value:Int):Void;
}

class Base implements Recorder {
	public var calls:Array<Int> = [];

	public function new() {}

	public function record(value:Int) {
		calls.push(value);
	}
}

class Derived extends Base {
	override public function record(value:Int) {
		calls.push(value * 10);
	}
}

// A virtual or interface call must not run when evaluating its arguments
// left the loop iteration
class Script {
	static function main() {
		var virtual:Base = new Derived();
		for (i in 0...4)
			virtual.record(if (i == 1) continue else i);
		var iface:Recorder = new Base();
		for (i in 0...4)
			iface.record(if (i == 2) continue else i);
		Sys.println(virtual.calls.join(",") + " " + (cast iface : Base).calls.join(","));
	}
}
