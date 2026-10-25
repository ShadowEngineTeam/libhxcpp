@:build(BuildNative.run())
class Main {
 static function main() {
  cpp.Lib.pushDllSearchPath(haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()),"../native/ndll",cpp.Lib.getBinDirectory()]));
  var fallback=cpp.Lib.load("auditprime","auditEcho",1);
  var fast=cpp.Prime.load("auditprime","auditEcho","ss",false);
  for(text in ["plain","caf\u00e9","\u65e5\u672c\u8a9e","\u{1f600}"]) {
   var ordinary:String=fallback(text);
   var direct:String=fast(text);
   Sys.println("direct Prime preserves the string: "+(direct==text));
   Sys.println("CFFI fallback preserves the same string: "+(ordinary==text));
  }
  var makeFallback=cpp.Lib.load("auditprime","auditMakeText",0);
  var makeFast=cpp.Prime.load("auditprime","auditMakeText","s",false);
  var made:String=makeFallback();
  Sys.println("direct Prime preserves a native Unicode result: "+(makeFast()=="\u65e5\u672c\u8a9e"));
  Sys.println("CFFI fallback preserves a native Unicode result: "+(made=="\u65e5\u672c\u8a9e"));
  var empty:String=fallback("");
  var missing:String=fallback(null);
  Sys.println("fallback preserves empty and null values: "+(empty=="" && missing==null));
  Sys.println("direct Prime preserves empty and null values: "+(fast("")=="" && fast(null)==null));
 }
}