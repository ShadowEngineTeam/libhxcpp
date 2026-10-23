import haxe.Int64;
class Main {
 static function result(mode:String,high:Int,divisor:Int):String {
  var input=Int64.make(high,0);
  var by=Int64.ofInt(divisor);
  return Int64.toStr(mode=="divide" ? input/by : input%by);
 }
 #if cpp
 static function child(mode:String,high:Int,divisor:Int,expected:String):Bool {
  var process=new sys.io.Process(Sys.programPath(),[mode,Std.string(high),Std.string(divisor)]);
  var status=process.exitCode();
  var actual=StringTools.trim(process.stdout.readAll().toString());
  process.close();
  return status==0 && actual==expected;
 }
 #end
 static function main() {
  var args=Sys.args();
  if(args.length>0) {
   Sys.println(result(args[0],Std.parseInt(args[1]),Std.parseInt(args[2])));
   return;
  }
  #if cpp
  var divide=child("divide",-2147483648,-1,"-9223372036854775808");
  var modulus=child("remainder",-2147483648,-1,"0");
  var control=child("divide",-1,2,"-2147483648") && child("remainder",-1,3,"-1");
  #else
  var divide=result("divide",-2147483648,-1)=="-9223372036854775808";
  var modulus=result("remainder",-2147483648,-1)=="0";
  var control=result("divide",-1,2)=="-2147483648" && result("remainder",-1,3)=="-1";
  #end
  Sys.println("minimum Int64 divided by negative one wraps: "+divide);
  Sys.println("minimum Int64 remainder by negative one is zero: "+modulus);
  Sys.println("ordinary signed division and remainder remain correct: "+control);
  var zero=false;
  try { result("divide",-1,0); } catch(e:Dynamic) { zero=e=="divide by zero"; }
  Sys.println("zero divisor remains a catchable Haxe exception: "+zero);
 }
}