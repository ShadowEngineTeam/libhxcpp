class Thing {
	public var count:Int = 3;

	public function new() {}

	public function add(a:Int):Int
		return count + a;

	public static function make(made:Bool):Thing
		return made ? new Thing() : null;

	// Native code that throws something other than a Haxe value
	public static function throwNative():Void {
		#if !cppia
		untyped __cpp__('throw "thrown by native code"');
		#end
	}
}
