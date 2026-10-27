class Item {
 public var kind:Int;
 public function new(kind:Int) this.kind=kind;
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
 static var held:Array<Item>;
 static var count=128;
 static var oldPopped=0;
 static var youngPopped=0;
 static var wrong=false;
 static function populate():Void {
  held=[for(i in 0...count) new Item(0)];
  var garbage=[for(i in 0...count) new Item(2)];
  if(garbage.length!=count) throw "setup";
 }
 static function register():Void for(item in held) cpp.vm.Gc.doNotKill(item);
 static function young():Void for(i in 0...64) cpp.vm.Gc.doNotKill(new Item(1));
 static function drain():Void {
  while(true) {
   var value:Item=cpp.vm.Gc.getNextZombie();
   if(value==null) break;
   if(value.kind==0) oldPopped++;
   else if(value.kind==1) youngPopped++;
   else wrong=true;
  }
 }
 static function release():Void held=null;
 #if audit_zombies
 static function measure():Float {
  var samples=[]; var full=0;
  for(i in 0...41) {
   var mark:Int=untyped __cpp__("hx::gByteMarkID");
   var start=haxe.Timer.stamp(); cpp.vm.Gc.run(false); var elapsed=(haxe.Timer.stamp()-start)*1000;
   if((untyped __cpp__("hx::gByteMarkID"))!=mark) full++;
   if(i>=10) samples.push(elapsed);
  }
  samples.sort((a,b)->a<b ? -1 : a>b ? 1 : 0);
  Sys.println("full collections in measured phase: "+full);
  return samples[samples.length>>1];
 }
 #end
 static function main() {
  #if audit_zombies
  count=Std.parseInt(Sys.args()[0]);
  #end
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  #if audit_zombies
  var before=measure();
  #end
  untyped __cpp__("runJoined({0})",register);
  cpp.vm.Gc.run(true);
  #if audit_zombies
  var after=measure();
  Sys.println("count="+count+", before_ms="+before+", registered_ms="+after);
  #end
  untyped __cpp__("runJoined({0})",young);
  for(i in 0...8) cpp.vm.Gc.run(false);
  untyped __cpp__("runJoined({0})",drain);
  Sys.println("young unreachable reservations enter the zombie queue: "+(youngPopped==64 && !wrong));
  Sys.println("live old reservations stay out of the zombie queue: "+(oldPopped==0));
  untyped __cpp__("runJoined({0})",release);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",drain);
  Sys.println("released old reservations enter the zombie queue once: "+(oldPopped==count && youngPopped==64 && !wrong));
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",drain);
  Sys.println("drained reservations do not reappear: "+(oldPopped==count && youngPopped==64 && !wrong));
 }
}

