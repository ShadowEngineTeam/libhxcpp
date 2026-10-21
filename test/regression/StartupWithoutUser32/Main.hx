@:cppFileCode('
#ifdef HX_WINDOWS
#include <windows.h>
static bool user32Loaded() { return GetModuleHandleA("user32.dll") != 0; }
#else
static bool user32Loaded() { return false; }
#endif
')
class Main {
	static function main() {
		var loaded:Bool = untyped __cpp__('user32Loaded()');
		Sys.println("user32 not loaded at startup: " + !loaded);
	}
}
