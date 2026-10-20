@:cppFileCode('
#if (HXCPP_API_LEVEL>=500)
#include <hx/thread/Scratch.hpp>

static bool scratchOk()
{
	bool ok = true;
	uint8_t *first = nullptr;
	{
		auto a = new hx::thread::Scratch(hx::thread::Scratch::alloc(16));
		first = a->view.ptr.ptr;
		auto b = hx::thread::Scratch::alloc(16);
		memset(b.view.ptr.ptr, 7, 16);
		delete a;
		auto c = hx::thread::Scratch::alloc(16);
		memset(c.view.ptr.ptr, 9, 16);
		ok = ok && b.view.ptr.ptr != c.view.ptr.ptr && b.view.ptr.ptr[0] == 7;
	}
	{
		auto a = hx::thread::Scratch::alloc(1);
		auto b = hx::thread::Scratch::alloc(1);
		ok = ok && a.view.ptr.ptr == first;
		ok = ok && ((size_t)a.view.ptr.ptr % 8) == 0 && ((size_t)b.view.ptr.ptr % 8) == 0;
	}
	return ok;
}
#else
static bool scratchOk() { return true; }
#endif
')
class Main {
	static function main() {
		var ok:Bool = untyped __cpp__('scratchOk()');
		Sys.println("scratch allocations stay separate and aligned: " + ok);
	}
}
