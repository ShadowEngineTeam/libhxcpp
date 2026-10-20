@:cppFileCode('
static int mustThrow(bool rethrow)
{
	if (rethrow)
		::hx::Rethrow(HX_CSTRING("thrown"));
	::hx::Throw(HX_CSTRING("thrown"));
}
')
class Main {
	static function main() {
		try {
			var value:Int = untyped __cpp__('mustThrow(false)');
			Sys.println("returned " + value);
		} catch (e:String) {
			Sys.println("caught: " + e);
		}
	}
}
