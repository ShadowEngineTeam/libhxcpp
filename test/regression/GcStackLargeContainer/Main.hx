@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#include <atomic>
struct StackChild : hx::Object { int id; StackChild(int value):id(value) {} };
static int childFinalized[2]={0,0};
static int parentFinalized[2]={0,0};
static std::atomic<int> childMarks[2];
struct StackParent : hx::Object {
 Dynamic child;
 int id;
 char padding[20000];
 StackParent(int value):id(value) { child=Dynamic(new StackChild(value)); HX_OBJ_WB_GET(this,child.mPtr); }
 void __Mark(hx::MarkContext *__inCtx) override { childMarks[id]++; HX_MARK_MEMBER(child); }
 #ifdef HXCPP_VISIT_ALLOCS
 void __Visit(hx::VisitContext *__inCtx) override { HX_VISIT_MEMBER(child); }
 #endif
};
static StackParent *pendingParent=0;
static bool parentAlive[2]={false,false};
static bool childAlive[2]={false,false};
static void finalizedChild(hx::Object *value) { childFinalized[static_cast<StackChild *>(value)->id]++; }
static void finalizedParent(hx::Object *value) { parentFinalized[static_cast<StackParent *>(value)->id]++; }
static void createParent(int id) {
 StackParent *parent=new StackParent(id);
 hx::GCSetFinalizer(parent->child.mPtr,finalizedChild);
 hx::GCSetFinalizer(parent,finalizedParent);
 pendingParent=parent;
}
static void collectParent(int id,bool explicitRoot) {
 StackParent *held=pendingParent;
 pendingParent=0;
 if(explicitRoot) hx::GCAddRoot(reinterpret_cast<hx::Object **>(&held));
 __hxcpp_collect(true);
 parentAlive[id]=parentFinalized[id]==0;
 childAlive[id]=childFinalized[id]==0;
 // Touch only the parent, and only if its finalizer did not run.
 if(parentAlive[id] && held->id!=id) parentAlive[id]=false;
 if(explicitRoot) hx::GCRemoveRoot(reinterpret_cast<hx::Object **>(&held));
}
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var phase=0;
 static function populate():Void untyped __cpp__("createParent({0})",phase);
 static function probe():Void untyped __cpp__("collectParent({0},{1})",phase,phase==1);
 static function main() {
  for(i in 0...2) {
   phase=i;
   untyped __cpp__("runJoined({0})",populate);
   untyped __cpp__("runJoined({0})",probe);
   cpp.vm.Gc.run(true);
  }
  var parent:Bool=untyped __cpp__("parentAlive[0]");
  var children:Bool=untyped __cpp__("(childAlive[0] && childMarks[0].load()>0)");
  var control:Bool=untyped __cpp__("(parentAlive[1] && childAlive[1] && childMarks[1].load()>0)");
  var cleanup:Bool=untyped __cpp__("(parentFinalized[0]==1 && parentFinalized[1]==1 && childFinalized[0]==1 && childFinalized[1]==1)");
  Sys.println("stack root preserves the large parent: "+parent);
  Sys.println("stack root traces the large parent children: "+children);
  Sys.println("explicit root preserves and traces children: "+control);
  Sys.println("released parents and children finalize once: "+cleanup);
  #if audit_counts
  var marks:Int=untyped __cpp__("childMarks[0].load()");
  var kept:Bool=untyped __cpp__("childAlive[0]");
  Sys.println("stack-only parent marks: "+marks+", child alive during collection: "+kept);
  #end
 }
}
