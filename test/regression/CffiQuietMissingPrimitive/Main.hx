@:build(BuildNative.run())
class Main {
 // Whether __hxcpp_get_proc_address finds the primitive, asked for its address
 // through the library's query function (ndll) or the query function itself
 static function found(lib:String,name:String,ndll:Bool,quiet:Bool):Bool {
  return untyped __cpp__('__hxcpp_get_proc_address({0},{1},{2},{3})!=0',lib,name,ndll,quiet);
 }
 static function main() {
  cpp.Lib.pushDllSearchPath(haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()),"../native/ndll",cpp.Lib.getBinDirectory()]));
  // First, while the library is being loaded, then once it is
  var missing=!found("quietlookup","quietMissing__1",true,true);
  missing=!found("quietlookup","quietMissing__1",true,true) && missing;
  Sys.println("a quiet lookup of a primitive the library lacks gives null: "+missing);
  Sys.println("a quiet lookup of a query function the library lacks gives null: "+!found("quietlookup","quietMissing__1",false,true));
  Sys.println("a quiet lookup of a primitive nothing registered gives null: "+!found("","quietMissing__1",true,true));
  stderr("expected: a lookup that is not quiet reports the missing primitive");
  Sys.println("a lookup that is not quiet gives null for a primitive the library lacks: "+!found("quietlookup","quietMissing__1",true,false));
  Sys.println("a quiet lookup finds a primitive the library has: "+found("quietlookup","quietPresent__1",true,true));
  var present=cpp.Lib.load("quietlookup","quietPresent",1);
  Sys.println("the primitive found runs: "+(present("value")=="value"));
 }
 static function stderr(message:String) {
  Sys.stderr().writeString(message+"\n");
 }
}
