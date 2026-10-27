@:cppFileCode('
#include <thread>
#include <string.h>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
	std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
// Large buffers that only a raw pointer on this stack holds: they are made on a
// joined worker, so no other stack keeps their arrays
static void makeRaw(volatile unsigned char **outBuffers, int inFrom, int inTo) {
	std::thread worker([=]() {
		hx::NativeAttach attach;
		for (int i = inFrom; i < inTo; i++) {
			::Array<unsigned char> a = ::Array_obj<unsigned char>::__new(4096, 4096);
			unsigned char *base = (unsigned char *)a->GetBase();
			memset(base, (i + 1) & 255, 4096);
			outBuffers[i] = base;
		}
	});
	hx::AutoGCFreeZone freeZone;
	worker.join();
}
static bool checkRaw(volatile unsigned char **inBuffers, int inCount) {
	for (int i = 0; i < inCount; i++)
		for (int j = 0; j < 4096; j += 256)
			if (inBuffers[i][j] != ((i + 1) & 255))
				return false;
	return true;
}
static void collect(Dynamic inChurn) {
	for (int i = 0; i < 2; i++)
		__hxcpp_collect(true);
	runJoined(inChurn);
}
static Array<bool> stackRoots(Dynamic inResize, Dynamic inChurn) {
	volatile unsigned char *buffers[32];
	Array<bool> results = Array_obj<bool>::__new(0, 4);
	makeRaw(buffers, 0, 16);
	inResize(128);
	collect(inChurn);
	results->push(checkRaw(buffers, 16));
	inResize(256);
	makeRaw(buffers, 16, 32);
	collect(inChurn);
	results->push(checkRaw(buffers, 32));
	inResize(16);
	collect(inChurn);
	results->push(checkRaw(buffers, 32));
	inResize(192);
	collect(inChurn);
	collect(inChurn);
	results->push(checkRaw(buffers, 32));
	return results;
}
')
class Main {
	static var pool:Array<haxe.io.Bytes>;
	static var target:Int;
	static var poolIntact:Bool;

	static function resize():Void {
		if (pool == null)
			pool = [];
		if (pool.length > target)
			pool.splice(target, pool.length - target);
		while (pool.length < target) {
			var b = haxe.io.Bytes.alloc(4096);
			b.fill(0, 4096, pool.length & 127);
			pool.push(b);
		}
	}

	static function resizeTo(n:Int):Void {
		target = n;
		untyped __cpp__("runJoined({0})", resize);
	}

	// Takes the memory of anything freed, with other contents
	static function churn():Void {
		var other = [for (i in 0...512) haxe.io.Bytes.alloc(4096)];
		for (b in other)
			b.fill(0, 4096, 0xee);
	}

	static function checkPool():Void {
		poolIntact = true;
		for (i in 0...pool.length)
			if (pool[i].get(0) != (i & 127) || pool[i].get(4095) != (i & 127))
				poolIntact = false;
	}

	// The stack scan finds large buffers through a sorted index of their bases,
	// which full collections keep while the buffers they swept are dropped from
	// it and the new survivors added. A base it lost would leave a buffer held
	// only on the stack to be freed
	static function main() {
		var results:Array<Bool> = untyped __cpp__("stackRoots({0},{1})", resizeTo, churn);
		untyped __cpp__("runJoined({0})", checkPool);
		Sys.println("stack-held buffers with 128 pooled: " + results[0]);
		Sys.println("stack-held buffers with 256 pooled: " + results[1]);
		Sys.println("stack-held buffers with 16 pooled: " + results[2]);
		Sys.println("stack-held buffers with 192 pooled: " + results[3]);
		Sys.println("pooled buffers intact: " + poolIntact);
		resizeTo(0);
		pool = null;
		for (i in 0...3)
			cpp.vm.Gc.run(true);
	}
}
