// The neko side: neko 2 keeps a string's or array's length above 4 tag bits
// and has Ints beyond 31 bits as values of their own
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
  // As lime and cpp.Prime.nekoInit do
  prim("neko_init",5)(function(s) return new String(s),function(len:Int) {
   var r=[];
   if(len>0) r[len-1]=null;
   return r;
  },null,true,false);

  var strlen:Dynamic=prim("nt_strlen",1);
  var type:Dynamic=prim("nt_type",1);
  var copy:Dynamic=prim("nt_copy",1);
  var short=neko.NativeString.ofString("abc");
  var long=neko.NativeString.ofString(StringTools.lpad("","x",1000));
  stderr('val_strlen of a 3 and a 1000-character neko string: ${strlen(short)}, ${strlen(long)}');
  Sys.println("val_strlen gives a neko string's length: "+(strlen(short)==3 && strlen(long)==1000));
  Sys.println("val_string and val_strlen give a neko string's characters: "+(copy(short)=="abc"));
  Sys.println("val_type sees a neko string as a string: "+(type(short)==3 && type(long)==3));
  Sys.println("val_strlen gives a String's length: "+(strlen("abc")==3));

  var arraySize:Dynamic=prim("nt_array_size",1);
  var arraySum:Dynamic=prim("nt_array_sum",1);
  var small=neko.NativeArray.ofArrayCopy([1,2,3,4]);
  var large=neko.NativeArray.alloc(300);
  for(i in 0...300) large[i]=i;
  stderr('val_array_size of a 4 and a 300-element neko array: ${arraySize(small)}, ${arraySize(large)}');
  Sys.println("val_array_size gives a neko array's length: "+(arraySize(small)==4 && arraySize(large)==300));
  Sys.println("val_array_i reads each element of a neko array: "+(arraySum(small)==10 && arraySum(large)==44850));
  Sys.println("val_type sees a neko array as an array: "+(type(small)==5 && type(large)==5));
  Sys.println("val_array_size gives an Array's length: "+(arraySize([1,2,3])==3));

  var intText:Dynamic=prim("nt_int_text",1);
  var intParse:Dynamic=prim("nt_int_parse",1);
  var number:Dynamic=prim("nt_number",1);
  var read=true,made=true,numbers=true,types=true;
  for(i in [0x40000000,-0x40000001,0x7fffffff,-0x7fffffff-1]) {
   stderr('$i: val_int ${intText(i)}, alloc_int ${intParse(neko.NativeString.ofString(Std.string(i)))}, val_type ${type(i)}');
   read=read && intText(i)==Std.string(i);
   made=made && intParse(neko.NativeString.ofString(Std.string(i)))==i;
   numbers=numbers && number(i)==i;
   types=types && type(i)==0xff;
  }
  Sys.println("val_int reads an Int beyond 31 bits: "+read);
  Sys.println("alloc_int makes an Int beyond 31 bits: "+made);
  Sys.println("val_number reads an Int beyond 31 bits: "+numbers);
  Sys.println("val_type sees an Int beyond 31 bits as an int: "+types);
  Sys.println("val_int reads a 31-bit Int: "+(intText(-5)=="-5" && intParse(neko.NativeString.ofString("12345"))==12345));
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
