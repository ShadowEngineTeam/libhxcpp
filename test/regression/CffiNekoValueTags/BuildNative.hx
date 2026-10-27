#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
class BuildNative {
 // The ndll is built for the neko that loads it, which can differ from the
 // test's architecture, so neko runs the program (built before Main) to say
 public static function run():Array<Field> {
  var neko=new sys.io.Process("neko",["bin/program.n","arch"]);
  var arch=StringTools.trim(neko.stdout.readAll().toString());
  neko.exitCode();
  neko.close();
  var define=switch(arch) {
   case "x86_64": "HXCPP_M64";
   case "arm64": "HXCPP_ARM64";
   case "x86": "HXCPP_M32";
   case _: Context.error('No hxcpp architecture for neko\'s "$arch"',Context.currentPos());
  }
  var original=Sys.getCwd();
  Sys.setCwd("native");
  var status=Sys.command("haxelib",["run","hxcpp","Build.xml","-D"+define]);
  Sys.setCwd(original);
  if(status!=0) Context.error("Native fixture build failed",Context.currentPos());
  return Context.getBuildFields();
 }
}
#end
