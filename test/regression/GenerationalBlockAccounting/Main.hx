@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var held:Array<haxe.io.Bytes>;
 static var versions:Array<Int>;
 static var stage=0;
 static var correct=true;
 static function value(index:Int,version:Int):haxe.io.Bytes {
  var size=((index+version)%4+1)*900;
  var bytes=haxe.io.Bytes.alloc(size);
  bytes.fill(0,size,(index+version)%251);
  bytes.set(size-1,(index+version+17)%251);
  return bytes;
 }
 static function populate():Void {
  versions=[for(i in 0...1024) 0];
  held=[for(i in 0...1024) value(i,0)];
 }
 static function mutate():Void {
  for(i in 0...held.length) if(i%8==stage%8) { versions[i]=stage+1; held[i]=value(i,stage+1); }
  var garbage=[for(i in 0...1024) value(i,stage+50)];
  if(garbage[1023].length<900) throw "garbage";
 }
 static function verify():Void {
  for(i in 0...held.length) {
   var b=held[i]; var v=versions[i]; var expected=((i+v)%4+1)*900;
   if(b.length!=expected || b.get(0)!=(i+v)%251 || b.get(expected>>1)!=(i+v)%251 || b.get(expected-1)!=(i+v+17)%251) correct=false;
  }
 }
 static function release():Void { held=null; versions=null; }
 static function main() {
  cpp.vm.Gc.run(true);
  var baseline=cpp.vm.Gc.memInfo(4);
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  var minor=false;
  for(round in 0...16) {
   stage=round;
   untyped __cpp__("runJoined({0})",mutate);
   for(i in 0...2) {
    var before:Int=untyped __cpp__("hx::gByteMarkID");
    cpp.vm.Gc.run(false);
    if((untyped __cpp__("hx::gByteMarkID"))==before) minor=true;
   }
   untyped __cpp__("runJoined({0})",verify);
  }
  Sys.println("minor collections exercise changing block occupancy: "+minor);
  Sys.println("old and replacement buffers retain their contents: "+correct);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",verify);
  Sys.println("full collection preserves block contents: "+correct);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  Sys.println("released block payload leaves live accounting: "+(cpp.vm.Gc.memInfo(4)-baseline<131072));
 }
}