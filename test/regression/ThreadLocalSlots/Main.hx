@:cppFileCode('
#include <hx/thread/ThreadLocal.hpp>
static bool legacyLeaks()
{
#if (HXCPP_API_LEVEL<500)
	__hxcpp_tls_set(0, ::String("legacy"));
	hx::thread::ThreadLocal_obj *local = new hx::thread::ThreadLocal_obj();
	return local->get() != null();
#else
	// API level 500 has no legacy slots to share an id with
	return false;
#endif
}
static void fillLocals()
{
	for(int i=0;i<200;i++)
		(new hx::thread::ThreadLocal_obj())->set(::String("old"));
}
static int staleLocals()
{
	int stale = 0;
	for(int i=0;i<200;i++)
		if ((new hx::thread::ThreadLocal_obj())->get() != null())
			stale++;
	return stale;
}
')
class Main {
	static function main() {
		Sys.println("legacy id leaks: " + (untyped __cpp__("legacyLeaks()") : Bool));
		untyped __cpp__("fillLocals()");
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		Sys.println("stale values: " + (untyped __cpp__("staleLocals()") : Int));
	}
}
