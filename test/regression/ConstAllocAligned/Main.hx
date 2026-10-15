class Main {
	static function main() {
		var cls:Bool = untyped __cpp__("(((size_t)::Main_obj::__mClass.mPtr) & 7) == 0");
		var boxed:Dynamic = "a";
		var box:Bool = untyped __cpp__("(((size_t){0}.mPtr) & 7) == 0", boxed);
		Sys.println('class aligned $cls');
		Sys.println('boxed char aligned $box');
	}
}
