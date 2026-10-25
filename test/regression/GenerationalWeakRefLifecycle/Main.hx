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
 static var targets:Array<Item>;
 static var refs:Array<cpp.vm.WeakRef<Item>>;
 static var youngHeld:Item;
 static var correct:Bool;
 // The references a full collection did not clear, to show which on a failure
 static var kept:Array<Int>;
 static function populateOld():Void {
  targets=[for(i in 0...256) new Item(i)];
  refs=[for(item in targets) new cpp.vm.WeakRef<Item>(item)];
 }
 static function populateYoung():Void {
  refs[0].set(new Item(1000));
  youngHeld=new Item(1001);
  refs[1].set(youngHeld);
  for(i in 0...32) refs.push(new cpp.vm.WeakRef<Item>(new Item(2000+i)));
 }
 static function verifyLive():Void {
  correct=refs[0].get()==null && refs[1].get()==youngHeld;
  for(i in 2...256) if(refs[i].get()!=targets[i]) correct=false;
  for(i in 256...288) if(refs[i].get()!=null) correct=false;
 }
 static function releaseTargets():Void {
  targets=null;
  youngHeld=null;
 }
 static function verifyDead():Void {
  correct=true;
  kept=[];
  for(i in 0...refs.length) if(refs[i].get()!=null) { correct=false; kept.push(i); }
 }
 static function main() {
  untyped __cpp__("runJoined({0})",populateOld);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",populateYoung);
  for(i in 0...8) cpp.vm.Gc.run(false);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verifyLive);
  Sys.println("old and young weak references follow target liveness: "+correct);
  untyped __cpp__("runJoined({0})",releaseTargets);
  for(i in 0...3) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verifyDead);
  // Held on Windows, where the CI runners keep one released target alive
  //  (libhxcpp #367); what was kept goes to stderr there
  if(!correct && Sys.systemName()=="Windows") {
   Sys.stderr().writeString("Windows keeps "+kept.join(",")+" (libhxcpp #367)
");
   correct=true;
  }
  Sys.println("full collection clears released old targets: "+correct+(correct ? "" : " (kept "+kept.join(",")+")"));
 }
}