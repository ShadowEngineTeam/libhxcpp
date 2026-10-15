import sys.thread.Condition;
import sys.thread.Lock;
import sys.thread.Mutex;
import sys.thread.Semaphore;
import sys.thread.Thread;

// The watchdog is plain C++, so it still runs when a collection deadlocks
@:cppFileCode('#include <thread>
#include <chrono>
#include <cstdio>
#include <cstdlib>
static void startWatchdog(int seconds)
{
	std::thread([seconds]() {
		std::this_thread::sleep_for(std::chrono::seconds(seconds));
		std::printf("deadlock\\n");
		std::fflush(stdout);
		std::_Exit(3);
	}).detach();
}')
class Main {
	static function churn() {
		var keep = [];
		for (i in 0...300000)
			keep.push("s" + i);
		return keep.length;
	}

	static function check(name:String, hold:Void->Void, poll:Void->Bool, free:Void->Void) {
		hold();
		var done = new Lock();
		Thread.create(() -> {
			while (!poll()) {}
			done.release();
		});
		churn();
		free();
		done.wait();
		Sys.println('$name ok');
	}

	static function main() {
		untyped __cpp__("startWatchdog(60)");
		var mutex = new Mutex();
		check("mutex", () -> mutex.acquire(), () -> mutex.tryAcquire(), () -> mutex.release());
		var condition = new Condition();
		check("condition", () -> condition.acquire(), () -> condition.tryAcquire(), () -> condition.release());
		var semaphore = new Semaphore(1);
		check("semaphore", () -> semaphore.acquire(), () -> semaphore.tryAcquire(0), () -> semaphore.release());
		var lock = new Lock();
		check("lock", () -> {}, () -> lock.wait(0), () -> lock.release());
	}
}
