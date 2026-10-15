@:cppFileCode('
namespace hx { wchar_t *ConvertToWChar(const char *inStr, int *ioLen); }

static bool outOfRangeCounted()
{
	if (sizeof(wchar_t)!=4)
		return true;
	wchar_t buf[3] = { (wchar_t)0x41, (wchar_t)-1, (wchar_t)0x110000 };
	String s = String::create(buf, 3);
	return s.length==3 && s.charCodeAt(1)==0xFFFD && s.charCodeAt(2)==0xFFFD;
}

static bool surrogatesJoined(String s)
{
	const wchar_t *w = s.wchar_str();
	if (sizeof(wchar_t)!=4)
		return w[1]==0xD83D && w[2]==0xDE00;
	return w[0]==0x61 && w[1]==0x1F600 && w[2]==0;
}

static bool fourByteDecoded()
{
	if (sizeof(wchar_t)!=4)
		return true;
	static const char utf8[] = { (char)0xF0, (char)0x9F, (char)0x98, (char)0x80, 0 };
	int len = 4;
	wchar_t *w = hx::ConvertToWChar(utf8, &len);
	return len==1 && w[0]==0x1F600;
}
')
class Main {
	static function main() {
		Sys.println("out of range " + (untyped __cpp__("outOfRangeCounted()") ? "ok" : "bad"));
		Sys.println("surrogates " + (untyped __cpp__("surrogatesJoined({0})", "a\u{1F600}") ? "ok" : "bad"));
		Sys.println("four byte " + (untyped __cpp__("fourByteDecoded()") ? "ok" : "bad"));
	}
}
