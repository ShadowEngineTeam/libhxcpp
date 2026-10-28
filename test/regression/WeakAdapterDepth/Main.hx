class Receiver {
 public var value:Int;
 public function new(value:Int) this.value=value;
 public function ping():Int return value;
}
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
struct DepthAdapter : hx::LocalFunc {
 Dynamic wrapped;
 DepthAdapter(Dynamic value) : wrapped(value) { HX_OBJ_WB_NEW_MARKED_OBJECT(this); }
 void *__GetHandle() const override { return wrapped.mPtr; }
 ::Dynamic __Run(const Array< ::Dynamic> &inArgs) override { return wrapped->__Run(inArgs); }
#if (HXCPP_API_LEVEL<500)
 Dynamic __run() override { return wrapped(); }
#endif
 int __ArgCount() const override { return 0; }
 void __Mark(hx::MarkContext *__inCtx) override { HX_MARK_MEMBER(wrapped); }
 #ifdef HXCPP_VISIT_ALLOCS
 void __Visit(hx::VisitContext *__inCtx) override { HX_VISIT_MEMBER(wrapped); }
 #endif
};
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
static Dynamic wrapDepth(Dynamic value,int depth) {
 for(int i=0;i<depth;i++) value=Dynamic(new DepthAdapter(value));
 return value;
}
static Dynamic deadCycle() {
 DepthAdapter *a=new DepthAdapter(Dynamic());
 DepthAdapter *b=new DepthAdapter(Dynamic(a));
 a->wrapped=Dynamic(b); HX_OBJ_WB_GET(a,b);
 return Dynamic(a);
}
')
class Main {
 static var depths=[0,1,15,16,32];
 static var receiver:Receiver;
 static var refs:Array<cpp.vm.WeakRef<Dynamic>>;
 static var cycle:cpp.vm.WeakRef<Dynamic>;
 static var results:Array<Bool>;
 static var released=false;
 static var cycleReleased=false;
 static function populate():Void {
  receiver=new Receiver(73);
  refs=[];
  for(depth in depths) {
   var wrapped:Dynamic=untyped __cpp__("wrapDepth({0},{1})",receiver.ping,depth);
   refs.push(new cpp.vm.WeakRef(wrapped));
  }
  cycle=new cpp.vm.WeakRef(untyped __cpp__("deadCycle()"));
 }
 static function verify():Void {
  results=[];
  for(ref in refs) {
   var method:Dynamic=ref.get();
   results.push(method!=null && method()==73);
  }
  cycleReleased=cycle.get()==null;
 }
 static function release():Void receiver=null;
 static function verifyReleased():Void {
  released=true;
  for(ref in refs) if(ref.get()!=null) released=false;
 }
 static function main() {
  untyped __cpp__("runJoined({0})",populate);
  for(i in 0...3) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verify);
  for(i in 0...depths.length) Sys.println("live receiver preserves adapter depth "+depths[i]+": "+results[i]);
  Sys.println("unreachable adapter cycle is cleared: "+cycleReleased);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verifyReleased);
  Sys.println("callbacks clear after receiver release: "+released);
 }
}
