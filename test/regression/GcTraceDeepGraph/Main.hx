import sys.io.Process;

class Node {
	public var next:Node;
	public var value:Int;

	public function new(next:Node, value:Int) {
		this.next = next;
		this.value = value;
	}
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
#ifdef HX_WINDOWS
#include <windows.h>
#endif
static void disableFaultDialog() {
 #ifdef HX_WINDOWS
 SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOGPFAULTERRORBOX);
 #endif
}
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static var head:Node;
	static var count = 0;

	static function populate():Void {
		var node:Node = null;
		for (i in 0...count)
			node = new Node(node, i);
		head = node;
	}

	// Each case runs in its own process, so a stack overflow fails only that case
	static function child(mode:String, n:Int):Bool {
		var process = new Process(Sys.programPath(), ["child", mode, Std.string(n)]);
		var output = process.stdout.readAll().toString();
		var code = process.exitCode();
		process.close();
		if (code != 0 || output != "ok")
			Sys.stderr().writeString('mode=$mode nodes=$n exit=$code output=$output\n');
		return code == 0 && output == "ok";
	}

	static function main() {
		var args = Sys.args();
		if (args.length == 3 && args[0] == "child") {
			untyped __cpp__("disableFaultDialog()");
			count = Std.parseInt(args[2]);
			untyped __cpp__("runJoined({0})", populate);
			cpp.vm.Gc.run(true);
			if (args[1] == "trace") {
				var traced = cpp.vm.Gc.trace(Node, false);
				if (traced != count) {
					Sys.print('wrong count $traced');
					return;
				}
			}
			var node = head;
			var expected = count - 1;
			while (node != null) {
				if (node.value != expected) {
					Sys.print("wrong value");
					return;
				}
				expected--;
				node = node.next;
			}
			Sys.print(expected == -1 ? "ok" : "wrong length");
			return;
		}
		Sys.println("normal collection preserves a deep linked graph: " + child("normal", 100000));
		Sys.println("trace counts a shallow graph without printing paths: " + child("trace", 128));
		Sys.println("trace counts a deep graph without terminating: " + child("trace", 100000));
	}
}
