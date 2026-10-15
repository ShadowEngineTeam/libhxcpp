#if cppia
extern class Test {
	static var foo(get, never):Int;
}
#else
class Test {
	public static var foo(get, never):Int;

	static function get_foo():Int
		return 42;
}
#end
