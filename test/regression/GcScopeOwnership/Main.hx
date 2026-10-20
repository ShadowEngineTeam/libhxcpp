@:cppFileCode('
#include <type_traits>
#include <hx/Native.h>
')
class Main {
	static function main() {
		Sys.println(untyped __cpp__('std::is_copy_constructible<hx::NativeAttach>::value || std::is_copy_assignable<hx::NativeAttach>::value') ? "NativeAttach copies" : "NativeAttach does not copy");
		Sys.println(untyped __cpp__('std::is_copy_constructible<hx::AutoGCFreeZone>::value || std::is_copy_assignable<hx::AutoGCFreeZone>::value') ? "AutoGCFreeZone copies" : "AutoGCFreeZone does not copy");
		var before:Int = untyped __cpp__('hx::GcGetThreadAttachedCount()');
		var inside:Int = untyped __cpp__('[]{ hx::NativeAttach a; hx::NativeAttach b; return hx::GcGetThreadAttachedCount(); }()');
		var after:Int = untyped __cpp__('hx::GcGetThreadAttachedCount()');
		Sys.println((inside - before) + " " + (after - before));
		untyped __cpp__('{ hx::AutoGCFreeZone zone; zone.close(); }');
		Sys.println("zone ok");
	}
}
