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
		var started = new sys.thread.Lock();
		Thread.create(() -> {
			started.release();
			while (true)
				work(kind);
		});
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
			var failed = 0;
			for (run in 0...40) {
				var proc = new sys.io.Process(Sys.programPath(), [kind]);
				var out = proc.stdout.readAll().toString();
				var code = proc.exitCode();
				proc.close();
				if (code != 0 || out.indexOf("main done") < 0)
					failed++;
			}
			Sys.println(kind + " worker at exit, 40 runs exit cleanly: " + (failed == 0));
		}
	}
}
