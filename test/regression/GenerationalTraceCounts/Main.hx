class Item {
 public var value:Int;
 public var label:String;
 public function new(value:Int) { this.value=value; label="item"+value; }
}
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var old:Array<Item>;
 static var young:Array<Item>;
 static function populateOld():Void old=[for(i in 0...128) new Item(i)];
 static function populateYoung():Void young=[for(i in 0...64) new Item(128+i)];
 static var valid=true;
 static function verify():Void {
  valid=old.length==128 && young.length==64;
  for(i in 0...old.length) if(old[i].value!=i) valid=false;
  for(i in 0...young.length) if(young[i].value!=128+i) valid=false;
 }
 static function release():Void { old=null; young=null; }
 static function main() {
  untyped __cpp__("runJoined({0})",populateOld);
  cpp.vm.Gc.run(true);
  var oldCount=cpp.vm.Gc.trace(Item,false);
  untyped __cpp__("runJoined({0})",populateYoung);
  var mixedCount=cpp.vm.Gc.trace(Item,false);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("trace counts retained old instances: "+(oldCount==128));
  Sys.println("trace counts old and young instances together: "+(mixedCount==192));
  Sys.println("retained contents remain correct: "+valid);
  untyped __cpp__("runJoined({0})",release);
  cpp.vm.Gc.run(true);
  Sys.println("trace excludes released instances: "+(cpp.vm.Gc.trace(Item,false)==0));
  #if audit_counts
  Sys.println("counts: "+oldCount+", "+mixedCount);
  #end
 }
}
