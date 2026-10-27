// Runs the neko program, which takes null, true and false from an hxcpp CFFI
// ndll before and after neko_init, and relays what it prints
@:build(BuildNative.run())
class Main {
 static function main() {
  var bin=haxe.io.Path.directory(Sys.programPath());
  var ndll=haxe.io.Path.normalize(haxe.io.Path.join([bin,"../native/ndll/nekoconsts"]));
  var neko=new sys.io.Process("neko",[haxe.io.Path.join([bin,"program.n"]),ndll]);
  var out=neko.stdout.readAll().toString();
  var err=neko.stderr.readAll().toString();
  var code=neko.exitCode();
  neko.close();
  Sys.stderr().writeString(err);
  Sys.print(StringTools.replace(out,"\r\n","\n"));
  Sys.println("neko ran the program to the end: "+(code==0));
 }
}
