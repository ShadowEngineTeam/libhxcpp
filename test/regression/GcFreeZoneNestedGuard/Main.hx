@:cppFileCode('
#include <hx/GC.h>
// TryGCFreeZone returns true only when the thread was outside a zone. After an
// inner guard that wrongly left the zone, it also enters it again, so the outer
// guard still has a zone to leave.
static bool nestedGuardPreservesOwner() {
 bool preserved;
 {
  hx::AutoGCFreeZone outer;
  { hx::AutoGCFreeZone inner; }
  preserved=!hx::TryGCFreeZone();
 }
 return preserved;
}
static bool nestedClosePreservesOwner() {
 bool preserved;
 {
  hx::AutoGCFreeZone outer;
  hx::AutoGCFreeZone inner;
  inner.close();
  inner.close();
  preserved=!hx::TryGCFreeZone();
 }
 return preserved;
}
static bool borrowedGuardPreservesOwner() {
 hx::EnterGCFreeZone();
 { hx::AutoGCFreeZone borrowed; }
 bool preserved=!hx::TryGCFreeZone();
 hx::ExitGCFreeZone();
 return preserved;
}
static bool singleGuardReleasesZone() {
 { hx::AutoGCFreeZone guard; }
 bool entered=hx::TryGCFreeZone();
 if(entered) hx::ExitGCFreeZone();
 return entered;
}
')
class Main {
	static function main() {
		var nested:Bool = untyped __cpp__("nestedGuardPreservesOwner()");
		var closed:Bool = untyped __cpp__("nestedClosePreservesOwner()");
		var borrowed:Bool = untyped __cpp__("borrowedGuardPreservesOwner()");
		var single:Bool = untyped __cpp__("singleGuardReleasesZone()");
		Sys.println("inner destruction preserves the outer GC-free zone: " + nested);
		Sys.println("inner close preserves the outer GC-free zone: " + closed);
		Sys.println("borrowed guard preserves an existing GC-free zone: " + borrowed);
		Sys.println("an owning guard leaves the zone on destruction: " + single);
		cpp.vm.Gc.run(true);
		Sys.println("collection works after all guard scopes complete: true");
	}
}
