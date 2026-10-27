@:cppFileCode('
#include <thread>
#include <hx/Native.h>
extern "C" long long sqlite3_memory_used(void);
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static inline var BLOB = 16 * 1024 * 1024;

	static var cnx:sys.db.Connection;
	static var usable:Bool;

	static function large():Float {
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
	}

	// SQLite's own count of the bytes its allocator holds
	static function native():Float {
		return untyped __cpp__("(Float)sqlite3_memory_used()");
	}

	static function collect():Float {
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		return large();
	}

	static function run(f:Void->Void) {
		untyped __cpp__("runJoined({0})", f);
	}

	static function fill(c:sys.db.Connection, bytes:Int) {
		c.request("CREATE TABLE t (payload BLOB)");
		c.request("INSERT INTO t VALUES (zeroblob(" + bytes + "))");
	}

	static function warm() {
		var c = sys.db.Sqlite.open(":memory:");
		c.request("SELECT 1");
		c.close();
	}

	static function open() {
		cnx = sys.db.Sqlite.open(":memory:");
		fill(cnx, BLOB);
	}

	static function verify() {
		var length:Int = cnx.request("SELECT length(payload) AS n FROM t").next().n;
		usable = length == BLOB;
	}

	static function close() {
		cnx.close();
		cnx = null;
	}

	static function abandon() {
		for (i in 0...16)
			fill(sys.db.Sqlite.open(":memory:"), 256 * 1024);
	}

	static function main() {
		run(warm);
		var baseline = collect();
		var nativeBaseline = native();

		run(open);
		Sys.println("database fixture retains native pages: " + (native() - nativeBaseline > BLOB));
		Sys.println("native database pages contribute to GC pressure: " + (collect() - baseline > BLOB));
		run(verify);
		Sys.println("retained database remains usable: " + usable);
		run(close);
		Sys.println("close releases native database pages: " + (native() - nativeBaseline < 1024 * 1024));
		Sys.println("close removes reported native pressure: " + (collect() - baseline < 1024 * 1024));

		run(abandon);
		Sys.println("abandoned databases contribute to GC pressure: " + (large() - baseline > 2 * 1024 * 1024));
		Sys.println("finalization removes reported native pressure: " + (collect() - baseline < 1024 * 1024));
		Sys.println("finalization closes abandoned databases: " + (native() - nativeBaseline < 1024 * 1024));
	}
}
