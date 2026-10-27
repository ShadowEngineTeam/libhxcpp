import cpp.NativeSsl;

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static inline var CONTEXTS = 256;

	static var conf:Dynamic;
	static var kept:Array<Dynamic>;
	static var usable:Bool;

	static function large():Float {
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
	}

	static function collect():Float {
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		return large();
	}

	static function run(f:Void->Void) {
		untyped __cpp__("runJoined({0})", f);
	}

	static function warm() {
		NativeSsl.init();
		conf = NativeSsl.conf_new(false);
		NativeSsl.ssl_close(NativeSsl.ssl_new(conf));
	}

	static function keep() {
		kept = [for (i in 0...CONTEXTS) NativeSsl.ssl_new(conf)];
	}

	static function verify() {
		usable = true;
		for (i in 0...kept.length) {
			try {
				NativeSsl.ssl_set_hostname(kept[i], "host" + i + ".example");
			} catch (e:Dynamic) {
				usable = false;
			}
		}
	}

	static function close() {
		for (ctx in kept)
			NativeSsl.ssl_close(ctx);
		kept = null;
	}

	static function abandon() {
		for (i in 0...CONTEXTS)
			NativeSsl.ssl_new(conf);
	}

	static function closeConf() {
		NativeSsl.conf_close(conf);
		conf = null;
	}

	static function main() {
		run(warm);
		var baseline = collect();

		run(keep);
		// Each context has a 16 KB record buffer each way
		Sys.println("native TLS context buffers contribute to GC pressure: " + (collect() - baseline > CONTEXTS * 32 * 1024));
		run(verify);
		Sys.println("retained TLS contexts remain usable after collection: " + usable);
		run(close);
		Sys.println("explicit close removes reported native pressure: " + (collect() - baseline < 1024 * 1024));

		run(abandon);
		Sys.println("abandoned TLS contexts contribute to GC pressure: " + (large() - baseline > CONTEXTS * 16 * 1024));
		Sys.println("finalization removes reported native pressure: " + (collect() - baseline < 1024 * 1024));
		run(closeConf);
	}
}
