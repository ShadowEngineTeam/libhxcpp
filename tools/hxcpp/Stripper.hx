import haxe.io.Path;

class Stripper
{
   public var mExe:String;
   public var mFlags:Array<String>;
   public var mExt:String;

   public function new(inExe:String)
   {
      mFlags = [];
      mExe = inExe;
   }

   public function strip(inTarget:String)
   {
      if (mExt!=null)
         inTarget = Path.withoutExtension(inTarget) + "." + mExt;

      var args = new Array<String>();
      args = args.concat(mFlags);
      args.push(inTarget);

      // runCommand splits a command like 'python "emstrip.py"' itself, keeping
      // quoted words whole
      var result = ProcessManager.runCommand("", mExe, args);
      if (result!=0)
      {
         Tools.exit(result);
         //throw "Error : " + result + " - build cancelled";
      }
   }
}
