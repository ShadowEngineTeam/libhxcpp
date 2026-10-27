class Holder {
 public var child:Dynamic;
 public function new() child=null;
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
 static var held:Array<Holder>;
 static var count=8192;
 static var correct=true;
 static function populate():Void held=[for(i in 0...count) new Holder()];
 static function reserveSpace():Void {
  var temporary=[for(i in 0...count*2) new Holder()];
  if(temporary.length!=count*2) throw "temporary";
 }
 static function mutate():Void {
  for(i in 0...count) {
   held[i].child={value:i};
  }
 }
 static function verify():Void {
  for(i in 0...count) if(held[i].child.value!=i) correct=false;
 }
 static function release():Void held=null;
 static function main() {
  untyped __cpp__("runJoined({0})",populate);
  untyped __cpp__("runJoined({0})",reserveSpace);
  cpp.vm.Gc.run(true);
  cpp.vm.Gc.enable(false);
  untyped __cpp__("runJoined({0})",mutate);
  cpp.vm.Gc.enable(true);
  cpp.vm.Gc.run(false);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("remembered burst preserves every child: "+correct);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("full collection preserves the retained graph: "+correct);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...16) cpp.vm.Gc.compact();
  Sys.println("collection after graph release completes: true");
 }
}

