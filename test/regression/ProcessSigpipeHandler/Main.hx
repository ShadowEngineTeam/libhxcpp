@:cppFileCode('
#ifndef _WIN32
#include <signal.h>
static volatile int sigpipeCalls = 0;
static void onSigpipe(int) { sigpipeCalls++; }
static void installHandler()
{
   struct sigaction sa;
   sa.sa_handler = onSigpipe;
   sigemptyset(&sa.sa_mask);
   sa.sa_flags = 0;
   sigaction(SIGPIPE, &sa, 0);
}
static bool handlerKept()
{
   struct sigaction sa;
   sigaction(SIGPIPE, 0, &sa);
   return sa.sa_handler == onSigpipe;
}
#else
static int sigpipeCalls = 0;
static void installHandler() {}
static bool handlerKept() { return true; }
#endif
')
class Main {
	static function main() {
		if (Sys.systemName() == "Windows") {
			Sys.println("handler kept: true");
			Sys.println("write to an ended child throws: true");
			Sys.println("handler calls: 0");
			return;
		}
		untyped __cpp__('installHandler()');
		var p = new sys.io.Process("sh", ["-c", "exit 0"]);
		p.exitCode();
		Sys.println("handler kept: " + (untyped __cpp__('handlerKept()') : Bool));
		var threw = false;
		try {
			for (i in 0...100)
				p.stdin.writeString("data that nobody reads\n");
			p.stdin.flush();
		} catch (e:Dynamic) {
			threw = true;
		}
		p.close();
		Sys.println("write to an ended child throws: " + threw);
		Sys.println("handler calls: " + (untyped __cpp__('(int)sigpipeCalls') : Int));
	}
}
