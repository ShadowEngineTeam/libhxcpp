@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var drops=0;
 static var retained:Float;
 static var baseline:Float;
 static function churn():Void {
  var previous=cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
  for(i in 0...128) {
   var b=haxe.io.Bytes.alloc(1024*1024);
   b.set(0,i);
   var current=cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
   if(current<previous) drops++;
   previous=current;
  }
  retained=cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE)-baseline;
 }
 static function main() {
  cpp.vm.Gc.run(true);
  baseline=cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
  #if audit_control
  var delta=0x7ffffffc;
  #else
  var delta=0x7fffffff;
  #end
  untyped __cpp__('hx::GCChangeManagedMemory({0},"boundary test")',delta);
  var counted=cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE)-baseline;
  untyped __cpp__("hx::GCReleaseManagedMemory((size_t){0})",delta);
  Sys.println("native accounting accepts a positive Int delta: "+(counted==delta));
  Sys.println("native accounting release balances the delta: "+(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE)==baseline));
  for(i in 0...16) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",churn);
  Sys.println("allocation pressure resumes after budget decay: "+(drops>0 && retained<48*1024*1024));
  cpp.vm.Gc.run(true);
  Sys.println("full collection releases discarded buffers: "+(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE)-baseline<1024*1024));
  #if audit_counts
  Sys.println("retained bytes: "+retained+", pool drops: "+drops);
  #end
 }
}
