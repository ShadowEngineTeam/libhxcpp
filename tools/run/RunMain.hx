import sys.FileSystem;
#if haxe4
import sys.thread.Thread;
#elseif neko
import neko.vm.Thread;
#end

class RunMain
{
   public static function log(s:String) Sys.println(s);
   public static function showMessage()
   {
      var varName = "HXCPP_NONINTERACTIVE";
      var nonInteractive:Bool =Sys.getEnv(varName)!=null;
      if (!nonInteractive)
         for(arg in Sys.args())
            if (arg.indexOf("-D"+varName)==0 )
               nonInteractive = true;

      var dir = Sys.getCwd();

      if (nonInteractive)
      {
         Sys.println('HXCPP in $dir is missing hxcpp.n');
         Sys.exit(-1);
      }

      log('This version of hxcpp ($dir) appears to be a source/developement version.');
      log("Before this can be used, you need to rebuild the main command-line tool:");
      log("  cd tools/hxcpp");
      log("  haxe compile.hxml");

      var gotUserResponse = false;
      Thread.create(function() {
         Sys.sleep(30);
         if (!gotUserResponse)
         {
            Sys.println("\nTimeout waiting for response.");
            Sys.println("Can't continue without hxcpp.n");
            Sys.exit(-1);
         }
      } );

      while(true)
      {
         Sys.print("\nWould you like to do this now [y/n]");
         var code = Sys.getChar(true);
         gotUserResponse = true;
         if (code<=32)
            break;
         var answer = String.fromCharCode(code);
         if (answer=="y" || answer=="Y")
         {
            log("");
            setup();
            if (!executeHxcpp())
               break;
            return;
         }
         if (answer=="n" || answer=="N")
            break;
      }

      Sys.println("\nCan't continue without hxcpp.n");
      Sys.exit(-1);
   }

   public static function setup()
   {
      log("Compiling hxcpp tool...");
      run("tools/hxcpp","haxe", [ "compile.hxml"]);
      log("Initial setup complete.");
   }

   public static function run(dir:String, command:String, args:Array<String>)
   {
      var oldDir:String = "";
      if (dir!="")
      {
         oldDir = Sys.getCwd();
         Sys.setCwd(dir);
      }
      Sys.command(command,args);
      if (oldDir!="")
         Sys.setCwd(oldDir);
   }

   // The folder compile-cpp.hxml puts BuildTool in when built on this host
   static function hostBinDir():Null<String>
   {
      var os = Sys.systemName();
      if ((new EReg("window","i")).match(os))
      {
         var proc = Sys.getEnv("PROCESSOR_IDENTIFIER");
         return proc!=null && (new EReg("\\barm","i")).match(proc) ? "WindowsArm64" : "Windows64";
      }

      var platform = (new EReg("mac","i")).match(os) ? "Mac" : (new EReg("linux","i")).match(os) ? "Linux" : null;
      if (platform==null)
         return null;

      var arch = "";
      try
      {
         var process = new sys.io.Process("uname", ["-m"]);
         arch = process.stdout.readAll().toString();
         process.close();
      }
      catch(e:Dynamic) { }

      return platform + (arch.indexOf("aarch64")>=0 || arch.indexOf("arm64")>=0 ? "Arm64" : arch.indexOf("64")>=0 ? "64" : "");
   }

   public static function executeHxcpp()
   {
      if (!sys.FileSystem.exists("./hxcpp.n"))
         return false;

      if (Sys.args().indexOf("-DHXCPP_NEKO_BUILDTOOL=1")<0)
      {
         var isWindows = (new EReg("window","i")).match(Sys.systemName());
         var binDir = hostBinDir();
         if (binDir!=null)
         {
            var compiled = 'bin/$binDir/BuildTool';
            if (isWindows)
               compiled += ".exe";
            if (FileSystem.exists(compiled))
            {
               var dotN = FileSystem.stat("hxcpp.n").mtime.getTime();
               var dotExe= FileSystem.stat(compiled).mtime.getTime();
               if (dotExe<dotN)
               {
                  var path = Sys.getCwd() + compiled;
                  Sys.println('Warning - $path file is out-of-date.  Please delete or rebuild.');
               }
               else
               {
                  Sys.exit( Sys.command( compiled, Sys.args() ) );
               }
            }
        }
      }

      neko.vm.Loader.local().loadModule("./hxcpp.n");
      return true;
   }

   public static function main()
   {
      // haxelib runs this in the library's folder and appends the caller's folder
      var args = Sys.args();
      var callerDir = Sys.getEnv("HAXELIB_RUN") == "1" && args.length > 0 ? args[args.length - 1] : Sys.getCwd();

      switch (args.length > 1 || Sys.getEnv("HAXELIB_RUN") != "1" ? args[0] : "")
      {
         case "setup":
            Redirect.setup(callerDir);
            return;
         case "off":
            Redirect.off(callerDir);
            return;
         default:
      }

      if (Sys.getEnv("HAXELIB_RUN") == "1")
         Redirect.followUpdates(callerDir);

      if (!executeHxcpp())
         showMessage();
   }
}
