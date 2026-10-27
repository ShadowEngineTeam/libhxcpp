class Target {
 public var value:Int;
 public function new(value:Int) this.value=value;
}
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#include <cstdio>
#include <cstdlib>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
static bool collectAndCatchExisting(Dynamic expected) {
 try { __hxcpp_collect(true); }
 catch(const Dynamic &error) { return error.mPtr==expected.mPtr; }
 return false;
}
static bool collectorPauseReleased() { return hx::gPauseForCollect.load()==0; }
static void reportUnreleasedCollector(bool caught,int calls) {
 std::puts(caught ? "finalizer exception reaches the caller: true" : "finalizer exception reaches the caller: false");
 std::puts("collector pause released after finalizer exception: false");
 // Avoid further managed operations while the collector is still paused.
 std::puts(calls==1 ? "finalizer executes exactly once: true" : "finalizer executes exactly once: false");
 std::fflush(stdout);
 std::_Exit(0);
}
')
class Main {
 static var calls=0;
 static var marker:Dynamic={tag:37};
 static function finalized(target:Target):Void {
  calls++;
  // Throw an existing Dynamic directly, without hx::Throw or managed allocation.
  untyped __cpp__("throw {0}",marker);
 }
 static function populate():Void {
  var target=new Target(37);
  cpp.vm.Gc.setFinalizer(target,cpp.Callable.fromStaticFunction(finalized));
 }
 static function main() {
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",populate);
  var caught:Bool=untyped __cpp__("collectAndCatchExisting({0})",marker);
  var released:Bool=untyped __cpp__("collectorPauseReleased()");
  if(!released) untyped __cpp__("reportUnreleasedCollector({0},{1})",caught,calls);
  cpp.vm.Gc.run(true);
  Sys.println("finalizer exception reaches the caller: "+caught);
  Sys.println("collector pause released after finalizer exception: "+released);

  Sys.println("finalizer executes exactly once: "+(calls==1));
 }
}
