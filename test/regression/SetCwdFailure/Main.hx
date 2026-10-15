@:cppFileCode('#ifdef HX_WINDOWS
#include <windows.h>
#endif
static ::String processEnv(::String name)
{
#ifdef HX_WINDOWS
	wchar_t buffer[1024];
	DWORD length = GetEnvironmentVariableW(name.wchar_str(), buffer, 1024);
	if (length > 0 && length < 1024)
		return ::String::create(buffer, length);
#endif
	return ::String();
}')
class Main {
	static function processEnv(name:String):String {
		return untyped __cpp__("::processEnv({0})", name);
	}

	static function main() {
		var before = Sys.getCwd();
		try {
			Sys.setCwd("no-such-dir");
			Sys.println("returned");
		} catch (e:Dynamic) {
			Sys.println("threw");
		}
		Sys.println(Sys.getCwd() == before ? "unchanged" : "changed");
		if (Sys.systemName() == "Windows") {
			Sys.setCwd(haxe.io.Path.directory(Sys.programPath()));
			var cwd = Sys.getCwd();
			var drive = processEnv("=" + cwd.charAt(0).toUpperCase() + ":");
			var same = drive != null && haxe.io.Path.normalize(drive).toLowerCase() == haxe.io.Path.normalize(cwd).toLowerCase();
			Sys.println(same ? "drive variable set" : 'drive variable is $drive');
			Sys.setCwd(before);
		} else {
			Sys.println("drive variable set");
		}
	}
}
