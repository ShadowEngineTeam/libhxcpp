import haxe.ds.IntMap;
import haxe.ds.StringMap;

class Item {
 public var value:Int;
 public function new(value:Int) this.value=value;
}
class Main {
 static function main() {
  var ints=new IntMap<Item>();
  var strings=new StringMap<Item>();
  var old=new Item(-1);
  for(i in 0...256) {
   ints.set(i,old);
   strings.set("old"+i,old);
  }
  cpp.vm.Gc.run(true);
  var correct=true;
  for(round in 0...32) {
   ints.set(0,new Item(round));
   strings.set("old0",new Item(round));
   for(i in 0...64) {
    var index=256+round*64+i;
    ints.set(index,new Item(index));
    strings.set("new"+index,new Item(index));
   }
   cpp.vm.Gc.run(false);
   if(ints.get(0).value!=round || strings.get("old0").value!=round) correct=false;
   if(ints.get(1)!=old || strings.get("old1")!=old) correct=false;
   for(i in 0...64) {
    var index=256+round*64+i;
    if(ints.get(index).value!=index || strings.get("new"+index).value!=index) correct=false;
   }
   if(round>0) {
    var removed=256+(round-1)*64;
    if(!ints.remove(removed) || !strings.remove("new"+removed)) correct=false;
    if(ints.exists(removed) || strings.exists("new"+removed)) correct=false;
   }
  }
  Sys.println("young map values and string keys survive collection: "+correct);
  cpp.vm.Gc.run(true);
  var last=256+31*64+63;
  Sys.println("full collection preserves map edges after growth: "+(ints.get(last).value==last && strings.get("new"+last).value==last && ints.get(1)==old && strings.get("old1")==old));
 }
}