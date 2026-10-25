import haxe.ds.WeakMap;

class Key {
	public var value:Int;
	public function new(value:Int) this.value=value;
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone;
 worker.join();
}
')
class Main {
	static var map:WeakMap<Key,Int>;
	static var survivor:Key;
	static function populate():Void {
		var keys=[for(i in 0...10000) new Key(i)];
		survivor=keys[0];
		map=new WeakMap();
		for(key in keys) map.set(key,key.value);
	}
	static function main() {
		untyped __cpp__("runJoined({0})",populate);
		for(i in 0...3) cpp.vm.Gc.run(true);
		var count=0;
		for(key in map.keys()) count++;
		Sys.println("only retained key survives: "+(count==1 && map.exists(survivor) && map.get(survivor)==0));
		map.set(new Key(-1),-1);
		Sys.println("surviving value remains after refill: "+(map.get(survivor)==0));
		map.clear();
		map.set(survivor,7);
		Sys.println("clear and reuse preserve semantics: "+(map.get(survivor)==7));
	}
}