package;

class Progress
{
   static inline var BAR_WIDTH = 30;

   public var current:Int;
   public var total:Int;

   var startTime:Float;

   public function new(inCurrent:Int, inTotal:Int)
   {
      current = inCurrent;
      total = inTotal;
      startTime = Sys.time();
   }

   /**
      Whether to keep a Gradle-style progress bar pinned to the last line of the terminal.
      Only on an interactive colour terminal: CI logs and pipes get one plain line per file.
   **/
   public static function useBar():Bool
   {
      if (Log.verbose || Log.quiet || Log.mute || Log.colorSupported != true)
         return false;
      for (name in ["CI", "GITHUB_ACTIONS", "HXCPP_NO_PROGRESS_BAR"])
         if (Sys.getEnv(name) != null)
            return false;
      return true;
   }

   public function getProgress():String
   {
      var percent = current / total;
      var pct = Std.int(percent * 1000) / 10;
      var progress = Std.string(pct);

      if (Std.int(pct) == pct)
         progress += ".0";

      return progress + "%";
   }

   public function getFormattedProgress():String
   {
      var progress = getProgress();

      var spaces = "";

      while ((spaces.length + progress.length) < 6)
         spaces += " ";

      return "\x1b[1m[\x1b[0m" + spaces + "\x1b[33;1m" + progress + "\x1b[0m\x1b[1m]\x1b[0m";
   }

   /** The bar line, for example `<==========-------------------> 34% COMPILING [1m 5s]`. */
   public function getBar():String
   {
      var filled = total <= 0 ? BAR_WIDTH : Std.int(BAR_WIDTH * current / total);
      if (filled > BAR_WIDTH)
         filled = BAR_WIDTH;

      var done = "";
      for (_ in 0...filled)
         done += "=";
      var left = "";
      for (_ in filled...BAR_WIDTH)
         left += "-";

      var percent = total <= 0 ? 100 : Std.int(100 * current / total);

      return "\x1b[1m<\x1b[32;1m" + done + "\x1b[0m\x1b[2m" + left + "\x1b[0m\x1b[1m>\x1b[0m \x1b[1m" + percent
         + "% COMPILING\x1b[0m \x1b[2m[" + formatTime(Sys.time() - startTime) + "] " + current + "/" + total + "\x1b[0m";
   }

   static function formatTime(seconds:Float):String
   {
      var s = Std.int(seconds);
      if (s < 60)
         return s + "s";
      if (s < 3600)
         return Std.int(s / 60) + "m " + (s % 60) + "s";
      return Std.int(s / 3600) + "h " + Std.int((s % 3600) / 60) + "m";
   }
}
