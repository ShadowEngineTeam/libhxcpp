import sys.db.Connection;
import sys.db.ResultSet;

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
	static var result:ResultSet;
	static var held:Connection;
	static var keepConnection:Bool;

	static function makeResult():Void {
		var connection=sys.db.Sqlite.open(":memory:");
		result=connection.request("SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3");
		held=keepConnection ? connection : null;
	}

	static function main() {
		for (control in [true,false]) {
			keepConnection=control;
			// Join after NativeAttach has detached, so the worker stack cannot
			// conservatively retain the connection after makeResult returns.
			untyped __cpp__("runJoined({0})",makeResult);
			for (i in 0...4) cpp.vm.Gc.run(true);
			var values:Array<Int>=[];
			while(result.hasNext()) values.push(result.next().value);
			Sys.println((control ? "held connection" : "result alone")+" preserves rows: "+(values.join(",")=="1,2,3"));
			if(held!=null) held.close();
			held=null;
			result=null;
		}
	}
}