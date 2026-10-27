// A worker still using the runtime when main returns: the statics it uses
// must not be destroyed under it at exit (libhxcpp #371). Each case runs in
// child processes, as the crash, where there is one, ends the process.
import sys.thread.Thread;

class Item {
	public var id:Int;
	public function new(id:Int) this.id = id;
}

class Main {
	static var items:Array<Item>;

	static function work(kind:String):Void {
		switch (kind) {
			case "env":
				Sys.getEnv("PATH");
			case "load":
				try cpp.Lib.load("no_such_library_371", "none", 0) catch (e:Dynamic) {}
			case "young":
				for (i in 0...64) items[(i * 37) % items.length] = new Item(i);
			default:
				throw "kind";
		}
	}

	static function child(kind:String):Void {
		items = [for (i in 0...4096) new Item(i)];
		cpp.vm.Gc.run(true);
		// Several workers loading, so one is likely to be inside the C
		//  library's file calls when main returns
		var workers = kind == "load" ? 8 : 1;
		var started = new sys.thread.Lock();
		for (_ in 0...workers)
			Thread.create(() -> {
				started.release();
				while (true)
					work(kind);
			});
		for (_ in 0...workers)
			started.wait();
		// Let the worker get going before main returns
		for (i in 0...200) work("env");
		Sys.println("main done");
	}

	static function main() {
		var args = Sys.args();
		if (args.length > 0) {
			child(args[0]);
			return;
		}
		for (kind in ["env", "load", "young"]) {
			// A failing load crashed at exit about once in a hundred runs,
			//  more often with other runs alongside, so it runs 8 at a time
			var batches = kind == "load" ? 100 : 40;
			var together = kind == "load" ? 8 : 1;
			var failed = 0;
			for (batch in 0...batches) {
				var procs = [for (_ in 0...together) new sys.io.Process(Sys.programPath(), [kind])];
				for (proc in procs) {
					var out = proc.stdout.readAll().toString();
					var code = proc.exitCode();
					proc.close();
					if (code != 0 || out.indexOf("main done") < 0) {
						Sys.stderr().writeString('$kind: exit code $code\n');
						failed++;
					}
				}
			}
			Sys.println(kind + " worker at exit, " + (batches * together) + " runs exit cleanly: " + (failed == 0));
		}
	}
}
