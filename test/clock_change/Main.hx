import haxe.Timer;
import sys.thread.Lock;
import sys.thread.Semaphore;
import sys.thread.Thread;

// Moves the system clock an hour forward during a timed wait, which must still
// take its full time. Changes the clock with sudo, so it runs only in CI.
class Main
{
   static var failed = false;

   static function monotonic():Float
   {
      return untyped __cpp__("::__time_stamp_ms() * 0.001");
   }

   static function setClock(time:Float)
   {
      var args = Sys.systemName() == "Mac"
         ? ["date", DateTools.format(Date.fromTime(time * 1000), "%m%d%H%M%Y.%S")]
         : ["date", "-s", "@" + Std.int(time)];
      var process = new sys.io.Process("sudo", args);
      if (process.exitCode() != 0)
      {
         Sys.println("could not set the clock");
         Sys.exit(1);
      }
      process.close();
   }

   static function check(name:String, wait:Float->Bool)
   {
      var shifted = new Lock();
      var wall = 0.0, then = 0.0;
      Thread.create(() -> {
         Sys.sleep(0.5);
         then = monotonic();
         wall = Sys.time();
         setClock(wall + 3600);
         shifted.release();
      });

      var start = monotonic();
      var stamp = Timer.stamp();
      var acquired = wait(2.0);
      var waited = monotonic() - start;
      var stamped = Timer.stamp() - stamp;
      shifted.wait();

      var now = wall + monotonic() - then;
      var moved = Sys.time() - now;
      setClock(now);
      if (Math.abs(moved - 3600) > 60)
      {
         Sys.println('$name: the clock was set back during the wait');
         Sys.exit(1);
      }

      var ok = !acquired && waited > 1.9 && waited < 3.0 && Math.abs(stamped - waited) < 0.2;
      Sys.println('$name: ' + (ok ? "waited 2s" : 'acquired $acquired after ${waited}s, Timer.stamp ${stamped}s'));
      if (!ok)
         failed = true;
   }

   public static function main()
   {
      var lock = new Lock();
      check("Lock.wait", t -> lock.wait(t));
      var semaphore = new Semaphore(0);
      check("Semaphore.tryAcquire", t -> semaphore.tryAcquire(t));
      Sys.exit(failed ? 1 : 0);
   }
}
