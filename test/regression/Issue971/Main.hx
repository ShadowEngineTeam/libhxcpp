import sys.thread.Thread;
import sys.thread.Lock;

function main() {
	var done = new Lock();
	var threads = 4;
	var errors = 0;
	var mutex = new sys.thread.Mutex();
	for (t in 0...threads) {
		Thread.create(() -> {
			try {
				var cnx = sys.db.Sqlite.open(":memory:");
				cnx.request("CREATE TABLE kv (k TEXT, v TEXT)");
				for (i in 0...3000) {
					cnx.request("INSERT INTO kv VALUES ('k" + i + "', 'v" + i + "')");
					var rs = cnx.request("SELECT COUNT(*) AS c FROM kv");
					rs.next();
					if (i % 500 == 0)
						cpp.vm.Gc.run(false);
				}
				cnx.close();
			} catch (e:Dynamic) {
				mutex.acquire();
				errors++;
				mutex.release();
			}
			done.release();
		});
	}
	for (t in 0...threads)
		done.wait();
	Sys.println("errors " + errors);
}
