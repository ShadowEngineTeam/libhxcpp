class Item {
 public var value:Int;
 public function new(value:Int) this.value=value;
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
 static var count=512;
 static var first=0;
 static var replacement=0;
 static function initial(item:Item):Void first++;
 static function replaced(item:Item):Void replacement++;
 static function populate():Void held=[for(i in 0...count) new Item(i)];
 static function register():Void for(item in held) cpp.vm.Gc.setFinalizer(item,cpp.Callable.fromStaticFunction(initial));
 static function change():Void {
  for(i in 0...count) {
   if(i%2==0) cpp.vm.Gc.setFinalizer(held[i],cpp.Callable.fromStaticFunction(replaced));
   else untyped __cpp__("__hxcpp_set_finalizer({0},0)",held[i]);
  }
 }
 static function release():Void held=null;
 static function median(samples:Array<Float>):Float {
  samples.sort((a,b)->a<b ? -1 : a>b ? 1 : 0);
  return samples[samples.length>>1];
 }
 static function main() {
  #if audit_promotion
  count=Std.parseInt(Sys.args()[0]);
  #end
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  #if audit_promotion
  var base=[];
  for(i in 0...21) { var start=haxe.Timer.stamp(); cpp.vm.Gc.run(true); if(i>3) base.push((haxe.Timer.stamp()-start)*1000); }
  #end
  untyped __cpp__("runJoined({0})",register);
  #if audit_promotion
  var start=haxe.Timer.stamp();
  #end
  cpp.vm.Gc.run(true);
  #if audit_promotion
  var promotion=(haxe.Timer.stamp()-start)*1000;
  var stable=[];
  for(i in 0...21) { var begin=haxe.Timer.stamp(); cpp.vm.Gc.run(true); if(i>3) stable.push((haxe.Timer.stamp()-begin)*1000); }
  Sys.println("count="+count+", baseline_ms="+median(base)+", promotion_ms="+promotion+", stable_ms="+median(stable));
  #end
  Sys.println("promotion preserves live targets without callbacks: "+(first==0 && replacement==0));
  untyped __cpp__("runJoined({0})",change);
  cpp.vm.Gc.run(true);
  Sys.println("replacement promotion preserves live targets: "+(first==0 && replacement==0));
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  Sys.println("replacement and removal survive promotion: "+(first==0 && replacement==Std.int((count+1)/2)));
 }
}

