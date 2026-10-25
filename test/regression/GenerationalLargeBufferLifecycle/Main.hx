@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var old:Array<haxe.io.Bytes>;
 static var young:haxe.io.Bytes;
 static var dead:cpp.vm.WeakRef<haxe.io.Bytes>;
 static var correct:Bool;
 static function populateOld():Void {
  old=[for(i in 0...1000) { var b=haxe.io.Bytes.alloc(8192); b.set(0,i%251); b.set(8191,(i+1)%251); b; }];
 }
 static function populateYoung():Void {
  young=haxe.io.Bytes.alloc(16384); young.set(16383,73);
  var discarded=haxe.io.Bytes.alloc(16384); discarded.set(0,91);
  dead=new cpp.vm.WeakRef(discarded);
  old[500]=young;
 }
 static function verify():Void {
  correct=dead.get()==null && old[500]==young && young.get(16383)==73;
  for(i in 0...1000) if(i!=500 && (old[i].get(0)!=i%251 || old[i].get(8191)!=(i+1)%251)) correct=false;
 }
 static function release():Void { old=null; young=null; }
 static function main() {
  cpp.vm.Gc.run(true);
  var baseline=cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_LARGE);
  untyped __cpp__("runJoined({0})",populateOld);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",populateYoung);
  for(i in 0...8) cpp.vm.Gc.run(false);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("old and young large buffer contents survive collection: "+correct);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("full collection preserves retained large buffers: "+correct);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  Sys.println("released large storage is reclaimed: "+(cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_LARGE)-baseline<1024*1024));
 }
}