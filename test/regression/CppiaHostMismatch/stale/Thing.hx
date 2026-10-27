// The script's view of Thing from another version of the host, where add took two arguments
class Thing {
	public var count:Int;

	public function new() {}

	public function add(a:Int, b:Int):Int
		return 0;

	public static function make(made:Bool):Thing
		return null;

	public static function throwNative():Void {}
}
