@:cppFileCode('
#include <thread>
#include <hx/Native.h>
struct RefTarget : hx::Object {
 int id;
 RefTarget(int value):id(value) {}
 HX_NATIVE_IMPLEMENTATION
};
typedef hx::Ref<RefTarget *> TargetRef;
static int finalized[5]={0,0,0,0,0};
static TargetRef *held[5]={0,0,0,0,0};
static void finalizedTarget(hx::Object *value) { finalized[static_cast<RefTarget *>(value)->id]++; }
static RefTarget *makeTarget(int id) {
 RefTarget *target=new RefTarget(id);
 hx::GCSetFinalizer(target,finalizedTarget);
 return target;
}
static void populateHolders() {
 // 0: copy constructed, then the original destroyed
 TargetRef *original=new TargetRef(makeTarget(0));
 held[0]=new TargetRef(*original);
 delete original;
 // 1: copy assigned into an empty holder
 original=new TargetRef(makeTarget(1));
 held[1]=new TargetRef();
 *held[1]=*original;
 delete original;
 // 2: copy assigned over a holder of target 3, which nothing else keeps
 original=new TargetRef(makeTarget(2));
 held[2]=new TargetRef(makeTarget(3));
 *held[2]=*original;
 delete original;
 // 4: assigned to itself
 held[4]=new TargetRef(makeTarget(4));
 TargetRef *same=held[4];
 *held[4]=*same;
}
static void releaseHolders() {
 for(int i=0;i<5;i++) { delete held[i]; held[i]=0; }
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
  var kept:Bool=untyped __cpp__("(finalized[0]==0 && finalized[1]==0 && finalized[2]==0 && finalized[4]==0)");
  var replaced:Bool=untyped __cpp__("finalized[3]==1");
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  var once:Bool=untyped __cpp__("(finalized[0]==1 && finalized[1]==1 && finalized[2]==1 && finalized[3]==1 && finalized[4]==1)");
  Sys.println("copied references keep their targets: "+kept);
  Sys.println("a replaced target is released: "+replaced);
  Sys.println("released references finalize each target once: "+once);
 }
}
