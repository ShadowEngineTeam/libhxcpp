class Item {
 public var kind:Int;
 public function new(kind:Int) this.kind=kind;
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone;
 worker.join();
}
')
class Main {
 static var live:Array<Item>;
 static var calls:Array<Int>=[0,0,0];
 static function finalized(item:Item):Void calls[item.kind]++;
 static function populateOld():Void {
  live=[for(i in 0...128) new Item(0)];
  for(item in live) cpp.vm.Gc.setFinalizer(item,cpp.Callable.fromStaticFunction(finalized));
 }
 static function populateYoung():Void {
  for(i in 0...128) {
   var item=new Item(1);
   cpp.vm.Gc.setFinalizer(item,cpp.Callable.fromStaticFunction(finalized));
   var removed=new Item(2);
   cpp.vm.Gc.setFinalizer(removed,cpp.Callable.fromStaticFunction(finalized));
   untyped __cpp__("__hxcpp_set_finalizer({0},0)",removed);
  }
 }
 static function unregisterLive():Void {
  for(item in live) untyped __cpp__("__hxcpp_set_finalizer({0},0)",item);
  live=null;
 }
 static function main() {
  untyped __cpp__("runJoined({0})",populateOld);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",populateYoung);
  for(i in 0...8) cpp.vm.Gc.run(false);
  cpp.vm.Gc.run(true);
  Sys.println("live old finalizers do not run: "+(calls[0]==0 && live.length==128));
  Sys.println("dead finalizers run exactly once: "+(calls[1]==128));
  Sys.println("unregistered finalizers do not run: "+(calls[2]==0));
  untyped __cpp__("runJoined({0})",unregisterLive);
  for(i in 0...3) cpp.vm.Gc.run(true);
  Sys.println("later collections do not repeat callbacks: "+(calls[0]==0 && calls[1]==128 && calls[2]==0));
 }
}