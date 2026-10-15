// How many of a group's files have compiled, shown before each file as it starts
class Progress
{
   var finished:Int;
   var total:Int;

   public function new(inTotal:Int)
   {
      finished = 0;
      total = inTotal;
   }

   public function label():String
   {
      var done = Std.string(finished);
      while (done.length < Std.string(total).length)
         done = " " + done;
      return "\x1b[1m[" + done + "/" + total + "]\x1b[0m";
   }

   public function fileDone()
   {
      Log.lock();
      finished++;
      Log.unlock();
   }
}
