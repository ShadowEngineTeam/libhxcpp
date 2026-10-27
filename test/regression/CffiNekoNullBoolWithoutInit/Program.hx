// The neko side: the ndll's null, true and false, before neko_init and after
class Program {
 static var lib:String;
 static function prim(name:String,args:Int):Dynamic {
  return neko.Lib.load(lib,name,args);
 }
 static function main() {
  var args=Sys.args();
  if(args[0]=="arch") {
   Sys.print(arch());
   return;
  }
  lib=args[0];
  check("without neko_init");
  // As lime and cpp.Prime.nekoInit do
  prim("neko_init",5)(function(s) return new String(s),function(len:Int) {
   var r=[];
   if(len>0) r[len-1]=null;
   return r;
  },null,true,false);
  check("after neko_init");
 }
 static function check(when:String) {
  // neko raises a primitive's C NULL result as an error
  var made=try {
   prim("nc_null",0)()==null && prim("nc_true",0)()==true && prim("nc_false",0)()==false;
  } catch(e:Dynamic) {
   stderr('$when: $e');
   false;
  }
  Sys.println('alloc_null and alloc_bool give neko\'s null, true and false $when: $made');
  Sys.println('val_bool reads neko\'s true $when: '+(prim("nc_reads_true",1)(true)==1 && prim("nc_reads_true",1)(false)==0));
  // Printing a C NULL crashes neko, so only once they compare as neko's values
  var fields:Dynamic=prim("nc_object",0)();
  var same=fields.n==null && fields.t==true && fields.f==false;
  Sys.println('they print as neko\'s values from an object\'s fields $when: '+(same && Std.string(fields.n)+","+fields.t+","+fields.f=="null,true,false"));
 }
 static function stderr(message:String) {
  Sys.stderr().writeString(message+"\n");
 }
 // sys_cpu_arch is new in neko 2.4
 static function arch():String {
  try {
   return neko.NativeString.toString(neko.Lib.load("std","sys_cpu_arch",0)());
  } catch(e:Dynamic) {
   return neko.Lib.load("std","sys_is64",0)() ? "x86_64" : "x86";
  }
 }
}
