import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

/**
   libhxcpp is installed under its own name, but the Haxe compiler, `-lib hxcpp`
   and libraries that depend on hxcpp all ask haxelib for "hxcpp". `setup` points
   that name at libhxcpp with `haxelib dev hxcpp`, so they all get the same
   runtime, and `off` removes it again. Upstream hxcpp, if installed, is never
   touched.

   The redirect names one installed version's folder, and `haxelib update
   libhxcpp` installs the new version beside it. So each run checks for an older
   folder: it moves the redirect to the current version and hands the run to it.
**/
class Redirect
{
   // Set on a run handed to the current version, so it is never handed on again
   static inline var FORWARDED = "LIBHXCPP_FORWARDED";

   public static function setup(callerDir:String)
   {
      var mine = Sys.getCwd();
      if (!haxelib(callerDir, ["dev", "hxcpp", mine]))
      {
         RunMain.log("Could not point hxcpp at libhxcpp.");
         Sys.exit(1);
      }
      RunMain.log('hxcpp now points at libhxcpp ${version(mine)}: the compiler, -lib hxcpp and libraries that depend on hxcpp all use it.');
      RunMain.log("To go back to hxcpp, run: haxelib run libhxcpp off");
   }

   public static function off(callerDir:String)
   {
      haxelib(callerDir, ["dev", "hxcpp"]);
      var hxcpp = libPath(callerDir, "hxcpp");
      if (hxcpp == null)
         RunMain.log("hxcpp no longer points at libhxcpp. hxcpp itself is not installed; to use it, run: haxelib install hxcpp");
      else
         RunMain.log('hxcpp no longer points at libhxcpp, and uses hxcpp ${version(hxcpp)} again.');
   }

   // Returns when the run should carry on here. Otherwise the current version
   // runs it, and this process exits with its code.
   public static function followUpdates(callerDir:String)
   {
      if (Sys.getEnv(FORWARDED) == "1")
         return;

      var currentPath = libPath(callerDir, "libhxcpp");
      // Not installed as libhxcpp, as when hxcpp points at a checkout: leave it be
      if (currentPath == null)
         return;
      var current = normalize(currentPath);

      var redirectPath = libPath(callerDir, "hxcpp");
      var redirect = redirectPath == null ? null : normalize(redirectPath);
      if (redirect != null && redirect != current && sameLibrary(redirect, current))
      {
         if (haxelib(callerDir, ["dev", "hxcpp", currentPath]))
            RunMain.log('libhxcpp: hxcpp now points at libhxcpp ${version(currentPath)}, the current version.');
      }

      var mine = normalize(Sys.getCwd());
      if (mine != current && sameLibrary(mine, current))
      {
         var args = Sys.args();
         // haxelib appends the caller's folder again
         args.pop();
         Sys.putEnv(FORWARDED, "1");
         Sys.setCwd(callerDir);
         Sys.exit(Sys.command("haxelib", ["run", "libhxcpp"].concat(args)));
      }
   }

   // Two versions of the same installed library: folders in the same project folder
   static function sameLibrary(a:String, b:String)
   {
      return parent(a) == parent(b);
   }

   static function parent(path:String)
   {
      var slash = path.lastIndexOf("/");
      return slash < 0 ? "" : path.substr(0, slash);
   }

   static function normalize(path:String)
   {
      var result = StringTools.trim(path).split("\\").join("/");
      while (result.length > 1 && StringTools.endsWith(result, "/"))
         result = result.substr(0, result.length - 1);
      if (Sys.systemName() == "Windows")
         result = result.toLowerCase();
      return result;
   }

   static function version(path:String)
   {
      try
      {
         var json:Dynamic = haxe.Json.parse(File.getContent(path + "/haxelib.json"));
         return Std.string(json.version);
      }
      catch (e:Dynamic)
      {
         return "?";
      }
   }

   // The folder haxelib resolves the library to from the caller's folder, which
   // may hold a local repository, or null when it is not installed
   static function libPath(callerDir:String, library:String):String
   {
      var oldDir = Sys.getCwd();
      Sys.setCwd(callerDir);
      var path:String = null;
      try
      {
         var process = new Process("haxelib", ["libpath", library]);
         var output = process.stdout.readAll().toString();
         if (process.exitCode() == 0)
         {
            var line = StringTools.trim(output.split("\n")[0]);
            if (line != "" && FileSystem.exists(line))
               path = line;
         }
         process.close();
      }
      catch (e:Dynamic) {}
      Sys.setCwd(oldDir);
      return path;
   }

   static function haxelib(callerDir:String, args:Array<String>)
   {
      var oldDir = Sys.getCwd();
      Sys.setCwd(callerDir);
      var code = Sys.command("haxelib", args);
      Sys.setCwd(oldDir);
      return code == 0;
   }
}
