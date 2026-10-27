import haxe.ds.WeakMap;
class Key {
 public var id:Int;
 public function new(id:Int) this.id=id;
}
class Link {
 public var next:Key;
 public function new(next:Key) this.next=next;
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
 static var map:WeakMap<Key,Link>;
 static var root:Key;
 static var all:Array<Key>;
 static var last:cpp.vm.WeakRef<Key>;
 static var count=128;
 static var correct=true;
 static var collected=false;
 static function populate():Void {
  var keys=[for(i in 0...count+1) new Key(i)];
  map=new WeakMap();
  for(i in 0...count) map.set(keys[i],new Link(keys[i+1]));
  root=keys[0]; last=new cpp.vm.WeakRef(keys[count]);
  #if audit_chain
  if(Sys.args().length>1) all=keys;
  #end
 }
 static function verify():Void {
  var key=root;
  for(i in 0...count) {
   var value=map.get(key);
   if(key==null || key.id!=i || value==null || value.next==null || value.next.id!=i+1) { correct=false; return; }
   key=value.next;
  }
  if(last.get()!=key) correct=false;
 }
 static function release():Void { root=null; all=null; }
 static function verifyReleased():Void {
  var n=0; for(_ in map.keys()) n++;
  collected=last.get()==null && n==0;
 }
 static function main() {
  #if audit_chain
  count=Std.parseInt(Sys.args()[0]);
  #end
  untyped __cpp__("runJoined({0})",populate);
  #if audit_chain
  var samples=[];
  for(i in 0...9) { var start=haxe.Timer.stamp(); cpp.vm.Gc.run(true); if(i>1) samples.push((haxe.Timer.stamp()-start)*1000); }
  samples.sort((a,b)->a<b ? -1 : a>b ? 1 : 0);
  Sys.println("links="+count+", median_ms="+samples[samples.length>>1]);
  #else
  cpp.vm.Gc.run(true);
  #end
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("indirect weak-map chain remains reachable: "+correct);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verifyReleased);
  Sys.println("unrooted chain and weak entries are collected: "+collected);
 }
}

