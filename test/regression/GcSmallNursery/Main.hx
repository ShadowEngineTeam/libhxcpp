class Item {
 public var value:Int;
 public function new(value:Int) this.value=value;
}
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#ifdef HX_WINDOWS
#include <windows.h>
static double processCpuSeconds() {
 FILETIME creation,exit,kernel,user;
 if(!GetProcessTimes(GetCurrentProcess(),&creation,&exit,&kernel,&user)) return 0;
 ULARGE_INTEGER k,u; k.LowPart=kernel.dwLowDateTime; k.HighPart=kernel.dwHighDateTime;
 u.LowPart=user.dwLowDateTime; u.HighPart=user.dwHighDateTime;
 return (double)(k.QuadPart+u.QuadPart)*0.0000001;
}
#else
static double processCpuSeconds() { return 0; }
#endif
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var held:Array<Item>;
 static var round=0;
 static var correct=true;
 static function populate():Void {
  held=[for(i in 0...128) new Item(i)];
  var garbage=[for(i in 0...4096) new Item(i)];
  if(garbage.length!=4096) throw "setup";
 }
 static function mutate():Void held[round%128]=new Item(1000+round);
 static function verify():Void if(held[round%128].value!=1000+round) correct=false;
 static function main() {
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  for(i in 0...16) {
   round=i;
   untyped __cpp__("runJoined({0})",mutate);
   cpp.vm.Gc.run(false);
   untyped __cpp__("runJoined({0})",verify);
  }
  Sys.println("small nursery collections preserve changed references: "+correct);
  #if audit_parallel
  var samples=[for(i in 0...2001) 0.0];
  for(i in 0...32) cpp.vm.Gc.run(false);
  var cpu:Float=untyped __cpp__("processCpuSeconds()");
  var wall=haxe.Timer.stamp();
  var full=0;
  for(i in 0...samples.length) {
   var mark:Int=untyped __cpp__("hx::gByteMarkID");
   var start=haxe.Timer.stamp();
   cpp.vm.Gc.run(false);
   samples[i]=(haxe.Timer.stamp()-start)*1000;
   if((untyped __cpp__("hx::gByteMarkID"))!=mark) full++;
  }
  var elapsed=(haxe.Timer.stamp()-wall)*1000;
  cpu=((untyped __cpp__("processCpuSeconds()"))-cpu)*1000;
  samples.sort((a,b)->a<b ? -1 : a>b ? 1 : 0);
  Sys.println("median_ms="+samples[1000]+", wall_ms="+elapsed+", cpu_ms="+cpu+", full_collections="+full);
  #end
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("full collection preserves the small retained graph: "+correct);
 }
}

