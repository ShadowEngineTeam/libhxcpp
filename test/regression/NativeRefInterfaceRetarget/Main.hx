@:cppFileCode('
#include <thread>
#include <hx/Native.h>
struct RefView { virtual hx::Object *__GetRealObject()=0; };
struct LeftView : RefView { int left; };
struct RightView : RefView { int right; };
struct ViewTarget : hx::Object, LeftView, RightView {
 int id;
 ViewTarget(int value):id(value) {}
 HX_NATIVE_IMPLEMENTATION
};
typedef hx::Ref<RefView *> ViewRef;
static int finalized[4]={0,0,0,0};
static ViewRef *held[3]={0,0,0};
static bool distinctOffsets=false;
static void finalizedTarget(hx::Object *value) { finalized[static_cast<ViewTarget *>(value)->id]++; }
static ViewTarget *makeTarget(int id) {
 ViewTarget *target=new ViewTarget(id);
 hx::GCSetFinalizer(target,finalizedTarget);
 return target;
}
static RefView *leftOf(ViewTarget *target) { return static_cast<LeftView *>(target); }
static RefView *rightOf(ViewTarget *target) { return static_cast<RightView *>(target); }
static void populateHolders() {
 ViewTarget *target=makeTarget(0);
 distinctOffsets=(char *)leftOf(target)!=(char *)rightOf(target);
 // 0: left view, then the right view of the same object
 held[0]=new ViewRef(leftOf(target));
 held[0]->setPtr(rightOf(target));
 // 1: right view, then the left view of the same object
 target=makeTarget(1);
 held[1]=new ViewRef(rightOf(target));
 held[1]->setPtr(leftOf(target));
 // 2: left view of target 3, then the right view of another object
 held[2]=new ViewRef(leftOf(makeTarget(3)));
 held[2]->setPtr(rightOf(makeTarget(2)));
}
static void releaseHolders() {
 for(int i=0;i<3;i++) { delete held[i]; held[i]=0; }
}
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static function populate():Void untyped __cpp__("populateHolders()");
 static function release():Void untyped __cpp__("releaseHolders()");
 static function main() {
  untyped __cpp__("runJoined({0})",populate);
  for(i in 0...3) cpp.vm.Gc.run(true);
  var distinct:Bool=untyped __cpp__("distinctOffsets");
  var kept:Bool=untyped __cpp__("(finalized[0]==0 && finalized[1]==0 && finalized[2]==0)");
  var replaced:Bool=untyped __cpp__("finalized[3]==1");
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  var once:Bool=untyped __cpp__("(finalized[0]==1 && finalized[1]==1 && finalized[2]==1 && finalized[3]==1)");
  Sys.println("interface views have different offsets: "+distinct);
  Sys.println("retargeted references keep their targets: "+kept);
  Sys.println("a replaced target is released: "+replaced);
  Sys.println("released references finalize each target once: "+once);
 }
}
