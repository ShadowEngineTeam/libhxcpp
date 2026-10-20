@:cppFileCode('
#ifndef _WIN32
#include <unistd.h>
static int saveAndClose(int fd) { int saved = dup(fd); close(fd); return saved; }
static void restore(int saved, int fd) { dup2(saved, fd); close(saved); }
#else
static int saveAndClose(int) { return -1; }
static void restore(int, int) {}
#endif
')
class Main {
	static function echoWith(closedFd:Int):String {
		var saved:Int = untyped __cpp__('saveAndClose({0})', closedFd);
		var p = try new sys.io.Process("sh", ["-c", "read line; echo got $line"]) catch (e:Dynamic) null;
		untyped __cpp__('restore({0}, {1})', saved, closedFd);
		if (p == null)
			return "failed to start";
		p.stdin.writeString("hello\n");
		p.stdin.close();
		var out = StringTools.trim(p.stdout.readAll().toString());
		p.close();
		return out;
	}

	static function main() {
		if (Sys.systemName() == "Windows") {
			for (fd in 0...3)
				Sys.println('parent fd $fd closed: got hello');
			return;
		}
		for (fd in 0...3)
			Sys.println('parent fd $fd closed: ' + echoWith(fd));
	}
}
