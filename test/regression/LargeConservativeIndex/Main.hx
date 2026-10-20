@:cppFileCode('
#include <stdlib.h>
#include <string.h>

static bool holdAndCollect(Array<String> made)
{
	const int COUNT = 100;
	const char *volatile held[COUNT];
	void *volatile noise[256];
	for (int i = 0; i < COUNT; i++)
		held[i] = made[i].raw_ptr();
	for (int i = 0; i < 256; i++)
		noise[i] = malloc(64);
	made->__SetSizeExact(0);

	static char junk[5000];
	memset(junk, 122, sizeof(junk));
	for (int r = 0; r < 4; r++)
	{
		__hxcpp_collect(true);
		for (int g = 0; g < 200; g++)
			::String::create(junk, sizeof(junk));
	}

	bool ok = true;
	for (int i = 0; i < COUNT; i++)
	{
		const char *s = held[i];
		for (int j = 0; j < 5000; j++)
			if (s[j] != (char)(97 + i % 26))
				ok = false;
	}
	for (int i = 0; i < 256; i++)
		free(noise[i]);
	return ok;
}
')
class Main {
	static var keep:Array<haxe.io.Bytes> = [];

	static function main() {
		for (i in 0...200)
			keep.push(haxe.io.Bytes.alloc(5000));
		var made = [for (i in 0...100) StringTools.rpad("", String.fromCharCode(97 + i % 26), 5000)];
		var ok:Bool = untyped __cpp__('holdAndCollect({0})', made);
		made = null;
		Sys.println("large strings held from a native stack survive: " + ok);
	}
}
