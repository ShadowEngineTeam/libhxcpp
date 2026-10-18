// View.slice(index, length) checked index + length > length with a signed
// 64-bit addition, so a huge length overflowed it, passed the check and gave a
// view far larger than its buffer. View is part of the API at level 500; the
// native code here includes it directly so the check runs under Haxe 4.3, and
// UBSan reports the overflow if it returns. openfl/libhxcpp#183
@:cppFileCode('
#include <cpp/marshal/View.hpp>
#include <stdint.h>

static unsigned char sliceData[16];

static const char *sliceResult(int64_t inIndex, int64_t inLength)
{
	cpp::marshal::View<unsigned char> view(cpp::Pointer<unsigned char>(sliceData), 16);
	try
	{
		cpp::marshal::View<unsigned char> part = view.slice(inIndex, inLength);
		return part.length == inLength ? "ok" : "wrong length";
	}
	catch(Dynamic &)
	{
		return "refused";
	}
}
')
class Main {
	static function check(label:String, call:String) {
		Sys.println(label + ": " + call);
	}

	static function main() {
		check("1, INT64_MAX", untyped __cpp__('::String(sliceResult(1, INT64_MAX))'));
		check("16, INT64_MAX", untyped __cpp__('::String(sliceResult(16, INT64_MAX))'));
		check("0, 16", untyped __cpp__('::String(sliceResult(0, 16))'));
		check("4, 12", untyped __cpp__('::String(sliceResult(4, 12))'));
		check("16, 0", untyped __cpp__('::String(sliceResult(16, 0))'));
		check("4, 13", untyped __cpp__('::String(sliceResult(4, 13))'));
		check("17, 0", untyped __cpp__('::String(sliceResult(17, 0))'));
		check("-1, 2", untyped __cpp__('::String(sliceResult(-1, 2))'));
		check("2, -1", untyped __cpp__('::String(sliceResult(2, -1))'));
		check("INT64_MAX, 1", untyped __cpp__('::String(sliceResult(INT64_MAX, 1))'));
	}
}
