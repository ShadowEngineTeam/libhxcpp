package;

import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

/** The runtime's SQLite primitives, which sys.db.Sqlite wraps (in hx4compat since Haxe 4.2). **/
@:buildXml('<include name="${HXCPP}/src/hx/libs/sqlite/Build.xml"/>')
extern class SqliteNative {
	@:native("_hx_sqlite_connect") static function connect(filename:String):Dynamic;
	@:native("_hx_sqlite_request") static function request(handle:Dynamic, sql:String):Dynamic;
	@:native("_hx_sqlite_close") static function close(handle:Dynamic):Void;
	@:native("_hx_sqlite_result_next") static function next(result:Dynamic):Dynamic;
}

/** A query of 100,000 rows of eight Int columns, every row kept until the end, as a result list is. **/
class SqliteRows extends Benchmark {
	static inline var N = 100000;
	static final SQL = "WITH RECURSIVE n(x) AS (VALUES(1000) UNION ALL SELECT x+1 FROM n WHERE x<" + (1000 + N - 1) + ") "
		+ "SELECT x AS a,x+1 AS b,x+2 AS c,x+3 AS d,x+4 AS e,x+5 AS f,x+6 AS g,x+7 AS h FROM n";

	public function new() {
		super("sqlite_rows", "rows", N);
	}

	override public function run():Int {
		var db = SqliteNative.connect(":memory:");
		var result = SqliteNative.request(db, SQL);
		var rows:Array<Dynamic> = [];
		while (true) {
			var row = SqliteNative.next(result);
			if (row == null)
				break;
			rows.push(row);
		}
		SqliteNative.close(db);
		var sum = 0;
		for (row in rows) {
			var a:Int = row.a;
			var h:Int = row.h;
			sum = (sum + a + h) | 0;
		}
		return (sum + rows.length) | 0;
	}
}

/** A whole 2 MB stream read from a loopback socket until the sender closes it, as Socket.read does. **/
class SocketRead extends Benchmark {
	static inline var SIZE = 2 << 20;

	var payload:Bytes;

	public function new() {
		super("socket_read", "MB", SIZE / (1 << 20));
	}

	override public function setup() {
		payload = Bytes.alloc(SIZE);
		for (i in 0...SIZE)
			payload.set(i, (i * 31) & 255);
	}

	override public function run():Int {
		var server = new Socket();
		server.bind(new Host("127.0.0.1"), 0);
		server.listen(1);
		var port = server.host().port;
		var sent = new Lock();
		var data = payload;
		Thread.create(() -> {
			var client = new Socket();
			client.connect(new Host("127.0.0.1"), port);
			client.output.writeFullBytes(data, 0, data.length);
			client.close();
			sent.release();
		});
		var conn = server.accept();
		var received:haxe.io.BytesData = cpp.NativeSocket.socket_read(@:privateAccess conn.__s);
		sent.wait();
		conn.close();
		server.close();
		return (received.length + received[SIZE >> 1] + received[SIZE - 1]) | 0;
	}
}

/**
	A native extension building a 2 MB result from 1 KB chunks with the CFFI
	buffer functions, without knowing the final size.
**/
@:cppFileCode('
// The runtime is linked in, so call its CFFI functions directly
#define STATIC_LINK
#include <hx/CFFI.h>

static int bench_cffi_buffer(int inTotal, int inChunk)
{
	char chunk[1024];
	for(int i=0;i<inChunk;i++)
		chunk[i] = (char)(i*7);
	buffer b = alloc_buffer_len(0);
	for(int done=0; done<inTotal; done+=inChunk)
		buffer_append_sub(b, chunk, inChunk);
	value v = buffer_val(b);
	return buffer_size(val_to_buffer(v)) + buffer_data(val_to_buffer(v))[inTotal-1];
}
')
class CffiBuffer extends Benchmark {
	static inline var SIZE = 2 << 20;

	public function new() {
		super("cffi_buffer", "MB", SIZE / (1 << 20));
	}

	override public function run():Int {
		return untyped __cpp__("bench_cffi_buffer({0}, 1024)", SIZE);
	}
}
