class Item {
 public var value:Int;
 public function new(value:Int) this.value=value;
}
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#include <hx/QuickVec.h>
#include <unordered_map>
#ifdef HXCPP_DEBUG
namespace hx {
 extern QuickVec<int> &sFreeObjectIds;
 extern QuickVec<hx::Object *> &sIdObjectMap;
 extern std::unordered_map<hx::Object *,int> &sObjectIdMap;
}
static double identityVectorBytes() { return hx::sFreeObjectIds.mAlloc*sizeof(int)+hx::sIdObjectMap.mAlloc*sizeof(hx::Object *); }
static int identityEntries() { return (int)hx::sObjectIdMap.size(); }
static int identityBuckets() { return (int)hx::sObjectIdMap.bucket_count(); }
static int reverseSlots() { return (int)hx::sIdObjectMap.size(); }
static int freeIds() { return (int)hx::sFreeObjectIds.size(); }
#endif
static bool idMatches(int id,Dynamic value) { return __hxcpp_id_obj(id)==value.mPtr; }
static bool idEmpty(int id) { return __hxcpp_id_obj(id)==0; }
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
 static var held:Array<Item>;
 static var ids:Array<Int>;
 static var count=2048;
 static var correct=true;
 static function populate():Void {
  held=[for(i in 0...count) new Item(i)];
  ids=[for(item in held) untyped __global__.__hxcpp_obj_id(item)];
 }
 static function checkLive():Void {
  for(i in 0...held.length) if(!(untyped __cpp__("idMatches({0},{1})",ids[i],held[i])) || held[i].value!=i) correct=false;
 }
 static function release():Void held=null;
 static function checkDead():Void {
  for(id in ids) if(!(untyped __cpp__("idEmpty({0})",id))) correct=false;
  ids=null;
 }
 static function main() {
  #if audit_identity
  count=Std.parseInt(Sys.args()[0]);
  #end
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",checkLive);
  Sys.println("burst identities resolve to their live targets: "+correct);
  untyped __cpp__("runJoined({0})",release);
  for(i in 0...3) cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",checkDead);
  for(i in 0...16) cpp.vm.Gc.compact();
  Sys.println("released burst identities stop resolving: "+correct);
  #if audit_identity
  var bytes:Float=untyped __cpp__("identityVectorBytes()");
  var entries:Int=untyped __cpp__("identityEntries()");
  var buckets:Int=untyped __cpp__("identityBuckets()");
  var slots:Int=untyped __cpp__("reverseSlots()");
  var free:Int=untyped __cpp__("freeIds()");
  Sys.println("entries="+entries+", reverse_slots="+slots+", free_ids="+free+", vector_capacity_bytes="+bytes+", hash_buckets="+buckets);
  #end
  count=128;
  untyped __cpp__("runJoined({0})",populate);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",checkLive);
  Sys.println("later registrations preserve lookup correctness: "+correct);
  untyped __cpp__("runJoined({0})",release);
  cpp.vm.Gc.run(true);
  untyped __cpp__("runJoined({0})",checkDead);
 }
}

