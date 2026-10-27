import sys.FileSystem;
import sys.io.File;

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
	static inline var FILES = 8;

	static var kept:sys.io.FileOutput;
	// Beside the program: the runner starts it from test/regression
	static var dir = haxe.io.Path.directory(Sys.programPath());

	static function path(i:Int):String {
		return dir + "/abandoned" + i + ".txt";
	}

	static function content(i:Int):String {
		return [for (line in 0...100) 'file $i line $line'].join("\n");
	}

	// Written but not closed, so the bytes are still in the stream's buffer
	static function abandon():Void {
		for (i in 0...FILES) {
			var out = File.write(path(i));
			out.writeString(content(i));
		}
	}

	static function flushed():Bool {
		for (i in 0...FILES)
			if (!FileSystem.exists(path(i)) || File.getContent(path(i)) != content(i))
				return false;
		return true;
	}

	// Deleting fails on Windows while the stream is open
	static function released():Bool {
		var all = true;
		for (i in 0...FILES)
			if (FileSystem.exists(path(i)))
				try
					FileSystem.deleteFile(path(i))
				catch (e:Dynamic)
					all = false;
		return all;
	}

	static function waitFor(check:() -> Bool):Bool {
		// Only a bound for a hang: the close happens soon after the collection
		var deadline = haxe.Timer.stamp() + 60;
		while (!check()) {
			if (haxe.Timer.stamp() > deadline)
				return false;
			Sys.sleep(0.01);
		}
		return true;
	}

	// An unreachable file's stream is closed after the collection that finds
	// it, on another thread, so a flush that waits does not hold up every thread
	static function main() {
		kept = File.write(dir + "/kept.txt");
		kept.writeString("before ");
		untyped __cpp__("runJoined({0})", abandon);
		for (i in 0...2)
			cpp.vm.Gc.run(true);
		Sys.println("abandoned files are flushed: " + waitFor(flushed));
		Sys.println("abandoned files are released: " + waitFor(released));
		kept.writeString("after");
		kept.close();
		Sys.println("a reachable file stays writable: " + (File.getContent(dir + "/kept.txt") == "before after"));
		FileSystem.deleteFile(dir + "/kept.txt");
	}
}
