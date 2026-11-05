package;

/**
   Compile progress.

   On an interactive colour terminal this draws a status area pinned to the bottom of the output,
   laid out like Gradle's rich console: the progress bar, then one line per compile thread with the
   file it is compiling, or `> IDLE`. Finished files are not listed; only other output
   (compiler warnings, errors) scrolls above the status area.

   Everywhere else (CI, pipes, `HXCPP_NO_PROGRESS_BAR`) every finished file gets one plain line.
**/
class Progress
{
   static inline var BAR_WIDTH = 15;

   /** Status lines are cut to this many characters, so they never wrap and break the redraw. */
   static inline var MAX_LINE = 79;

   /** The progress currently drawing a status area, if any. */
   static var active:Null<Progress> = null;

   /** How many lines of status area are on screen right now. */
   static var drawnLines = 0;

   public var current:Int;
   public var total:Int;

   var startTime:Float;
   var workers:Array<Null<String>>;

   public function new(inCurrent:Int, inTotal:Int, inWorkers:Int = 1)
   {
      current = inCurrent;
      total = inTotal;
      startTime = Sys.time();
      workers = [for (_ in 0...(inWorkers < 1 ? 1 : inWorkers)) null];
   }

   /**
      Whether to draw the status area. Only on an interactive colour terminal:
      CI logs and pipes get one plain line per file.
   **/
   public static function useBar():Bool
   {
      return !disabled && !(Log.verbose || Log.quiet || Log.mute || Log.colorSupported != true);
   }

   static var disabled = false;

   /**
      Turns the status area off for CI and for `HXCPP_NO_PROGRESS_BAR`, given as a define
      (`-D HXCPP_NO_PROGRESS_BAR`) or as an environment variable. The defines include the environment.
   **/
   public static function setup(defines:haxe.ds.StringMap<String>):Void
   {
      if (defines.exists("HXCPP_NO_PROGRESS_BAR"))
         disabled = true;

      // CI is set by GitHub Actions, GitLab, CircleCI, Travis, Bitbucket, Buildkite and most others;
      // the rest are services that do not set it.
      for (name in ["CI", "GITHUB_ACTIONS", "TF_BUILD", "JENKINS_URL", "TEAMCITY_VERSION", "BUILDKITE", "APPVEYOR", "CODEBUILD_BUILD_ID"])
         if (Sys.getEnv(name) != null)
            disabled = true;
   }

   /** Marks `inName` as being compiled by thread `inTid` and redraws the status area. */
   public function begin(inTid:Int, inName:String):Void
   {
      workers[slot(inTid)] = inName;
      render(null);
   }

   /** Marks thread `inTid` as idle and redraws. Like Gradle, finished files are not listed. */
   public function end(inTid:Int):Void
   {
      current++;
      workers[slot(inTid)] = null;
      render(null);
   }

   /** Removes the status area for good, once the group is done. */
   public function finish():Void
   {
      Log.lock();
      if (active == this)
      {
         Log.print(erase());
         Sys.stdout().flush();
         active = null;
      }
      Log.unlock();
   }

   /**
      Removes the status area so other output starts on a clean line.
      It comes back on the next update.
   **/
   public static function clearActive():Void
   {
      Log.lock();
      if (active != null && drawnLines > 0)
      {
         Log.print(erase());
         Sys.stdout().flush();
      }
      Log.unlock();
   }

   function slot(inTid:Int):Int
   {
      return (inTid < 0 || inTid >= workers.length) ? 0 : inTid;
   }

   function render(inLine:Null<String>):Void
   {
      Log.lock();
      active = this;

      var out = erase();
      if (inLine != null)
         out += inLine + "\n";

      var lines = [getBar()];
      for (worker in workers)
         lines.push(worker == null ? "\x1b[2m> IDLE\x1b[0m" : "\x1b[1m>\x1b[0m " + colorPath(cut(worker, MAX_LINE - 2)));

      out += lines.join("\n");
      drawnLines = lines.length;

      Log.print(out);
      Sys.stdout().flush();
      Log.unlock();
   }

   /** Moves back to the first line of the status area and clears everything below it. */
   static function erase():String
   {
      if (drawnLines == 0)
         return "";

      var out = drawnLines > 1 ? "\x1b[" + (drawnLines - 1) + "A" : "";
      drawnLines = 0;
      return out + "\r\x1b[J";
   }

   /** Same colours as the finished file lines: the folder in yellow, the file name in bold yellow. */
   static function colorPath(inPath:String):String
   {
      var slash = inPath.lastIndexOf("/");
      if (slash < 0)
         return "\x1b[33;1m" + inPath + "\x1b[0m";
      return "\x1b[33m" + inPath.substr(0, slash + 1) + "\x1b[33;1m" + inPath.substr(slash + 1) + "\x1b[0m";
   }

   static function cut(inText:String, inMax:Int):String
   {
      if (inText.length <= inMax)
         return inText;
      return "..." + inText.substr(inText.length - (inMax - 3));
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

   /** The bar line in Gradle's ASCII style, for example `[#####..........] 34% COMPILING [1m 5s]`. */
   public function getBar():String
   {
      var filled = total <= 0 ? BAR_WIDTH : Std.int(BAR_WIDTH * current / total);
      if (filled > BAR_WIDTH)
         filled = BAR_WIDTH;

      var done = "";
      for (_ in 0...filled)
         done += "#";
      var left = "";
      for (_ in filled...BAR_WIDTH)
         left += ".";

      var percent = total <= 0 ? 100 : Std.int(100 * current / total);

      return "\x1b[1m[\x1b[32;1m" + done + "\x1b[0m\x1b[1m" + left + "] " + percent + "% COMPILING [" + formatTime(Sys.time() - startTime)
         + "]\x1b[0m \x1b[2m" + current + "/" + total + "\x1b[0m";
   }

   /** Elapsed time the way Gradle shows it: `5s`, `1m 5s`, `1h 2m`. */
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
