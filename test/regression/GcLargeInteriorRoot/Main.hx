@:cppFileCode('
#include <thread>
#include <hx/Native.h>
struct SmallInterior : hx::Object { int value; SmallInterior():value(73) {} };
// The padding puts it among the large allocations
struct LargeInterior : hx::Object { int value; char padding[20000]; LargeInterior():value(73) {} };
static int finalized[3]={0,0,0};
static void smallFinalizer(hx::Object *) { finalized[0]++; }
static void largeFinalizer(hx::Object *) { finalized[1]++; }
static void baseFinalizer(hx::Object *) { finalized[2]++; }
static void *transfer=0;
static bool alive[3]={false,false,false};
static void createTarget(int mode) {
 if(mode==0) {
  SmallInterior *target=new SmallInterior();
  hx::GCSetFinalizer(target,smallFinalizer);
  transfer=&target->value;
 } else {
  LargeInterior *target=new LargeInterior();
  hx::GCSetFinalizer(target,mode==1 ? largeFinalizer : baseFinalizer);
  transfer=mode==1 ? static_cast<void *>(&target->value) : static_cast<void *>(target);
 }
}
// Only the field (or base) address is held, in a local, across the collection
static void collectTarget(int mode) {
 void *volatile held=transfer;
 transfer=0;
 __hxcpp_collect(true);
 alive[mode]=finalized[mode]==0;
 // Read the value only once the finalizer count shows its owner survived
 if(alive[mode]) {
  if(mode==2) alive[mode]=static_cast<LargeInterior *>(held)->value==73;
  else alive[mode]=*static_cast<int *>(held)==73;
 }
}
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static var mode = 0;

	static function create():Void
		untyped __cpp__("createTarget({0})", mode);

	static function probe():Void
		untyped __cpp__("collectTarget({0})", mode);

	static function main() {
		for (i in 0...3) {
			mode = i;
			untyped __cpp__("runJoined({0})", create);
			untyped __cpp__("runJoined({0})", probe);
			cpp.vm.Gc.run(true);
		}
		var small:Bool = untyped __cpp__("alive[0]");
		var large:Bool = untyped __cpp__("alive[1]");
		var base:Bool = untyped __cpp__("alive[2]");
		var cleanup:Bool = untyped __cpp__("(finalized[0]==1 && finalized[1]==1 && finalized[2]==1)");
		Sys.println("small object survives through a field pointer: " + small);
		Sys.println("large object survives through a field pointer: " + large);
		Sys.println("large object survives through a base pointer: " + base);
		Sys.println("released objects finalize exactly once: " + cleanup);
		if (!cleanup)
			Sys.stderr().writeString("finalized " + untyped __cpp__("finalized[0]") + " " + untyped __cpp__("finalized[1]") + " "
				+ untyped __cpp__("finalized[2]") + "\n");
	}
}
