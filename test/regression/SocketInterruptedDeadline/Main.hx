import sys.net.Host;
import sys.net.Socket;

@:cppFileCode('
#if defined(__linux__)
#include <signal.h>
#include <sys/time.h>
static volatile int sTicks = 0;
static struct sigaction sOld;
static void onAlarm(int)
{
   if (++sTicks >= 30)
   {
      struct itimerval stop = {};
      setitimer(ITIMER_REAL, &stop, 0);
   }
}
static void startAlarms()
{
   sTicks = 0;
   struct sigaction sa = {};
   sa.sa_handler = onAlarm;
   sigemptyset(&sa.sa_mask);
   sigaction(SIGALRM, &sa, &sOld);
   struct itimerval every = {};
   every.it_interval.tv_usec = 10000;
   every.it_value.tv_usec = 10000;
   setitimer(ITIMER_REAL, &every, 0);
}
static void stopAlarms()
{
   struct itimerval stop = {};
   setitimer(ITIMER_REAL, &stop, 0);
   sigaction(SIGALRM, &sOld, 0);
}
#else
static void startAlarms() {}
static void stopAlarms() {}
#endif
')
class Main {
	static function kept(wait:Void->Void):Bool {
		untyped __cpp__('startAlarms()');
		var t0 = haxe.Timer.stamp();
		wait();
		var elapsed = haxe.Timer.stamp() - t0;
		untyped __cpp__('stopAlarms()');
		Sys.sleep(0.4);
		return elapsed < 0.2;
	}

	static function main() {
		if (Sys.systemName() != "Linux") {
			Sys.println("select kept deadline: true");
			Sys.println("fast_select kept deadline: true");
			Sys.println("poll kept deadline: true");
			return;
		}
		var server = new Socket();
		server.bind(new Host("127.0.0.1"), 0);
		server.listen(1);
		var client = new Socket();
		client.connect(new Host("127.0.0.1"), server.host().port);
		var peer = server.accept();
		Sys.println("select kept deadline: " + kept(() -> Socket.select([client], [], [], 0.05)));
		Sys.println("fast_select kept deadline: " + kept(() -> cpp.NativeSocket.socket_fast_select([@:privateAccess client.__s], [], [], 0.05)));
		var poll = new cpp.net.Poll(4);
		poll.prepare([client], []);
		Sys.println("poll kept deadline: " + kept(() -> poll.events(0.05)));
		client.close();
		peer.close();
		server.close();
	}
}
