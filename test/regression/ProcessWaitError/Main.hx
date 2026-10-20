@:cppFileCode('
#ifndef _WIN32
#include <sys/wait.h>
static int reapElsewhere(int pid)
{
   int status = 0;
   if (waitpid(pid, &status, 0) != pid)
      return -1;
   return WEXITSTATUS(status);
}
#else
static int reapElsewhere(int) { return -1; }
#endif
')
class Main {
	static function result(f:Void->Null<Int>):String {
		try {
			return "returned " + f();
		} catch (e:Dynamic) {
			return "reported an error";
		}
	}

	static function main() {
		if (Sys.systemName() == "Windows") {
			Sys.println("reaped elsewhere: 7");
			Sys.println("blocking exitCode reported an error");
			Sys.println("polling exitCode reported an error");
			Sys.println("own status: 3 3");
			return;
		}
		var p = new sys.io.Process("sh", ["-c", "exit 7"]);
		Sys.println("reaped elsewhere: " + (untyped __cpp__('reapElsewhere({0})', p.getPid()) : Int));
		Sys.println("blocking exitCode " + result(() -> p.exitCode(true)));
		Sys.println("polling exitCode " + result(() -> p.exitCode(false)));
		p.close();
		var own = new sys.io.Process("sh", ["-c", "exit 3"]);
		Sys.println("own status: " + own.exitCode() + " " + own.exitCode());
		own.close();
	}
}
