class Main {
 // Runs this program again to throw the value uncaught: its exit code and
 // the lines it prints
 static function child(kind:String):{code:Int,lines:Array<String>} {
  var process=new sys.io.Process(Sys.programPath(),[kind]);
  var out=process.stdout.readAll().toString();
  var err=process.stderr.readAll().toString();
  var code=process.exitCode();
  process.close();
  Sys.stderr().writeString('throwing $kind: exit code $code\n$out$err');
  return {code:code,lines:out.split("\n").map(StringTools.trim)};
 }
 static function main() {
  var args=Sys.args();
  if(args.length>0) {
   if(args[0]=="null")
    throw null;
   throw "thrown";
  }
  var thrownNull=child("null");
  Sys.println("an uncaught null ends the program with a failure code: "+(thrownNull.code!=0));
  Sys.println("an uncaught null is reported as Error : null: "+thrownNull.lines.contains("Error : null"));
  var thrownString=child("string");
  Sys.println("an uncaught String ends the program with a failure code: "+(thrownString.code!=0));
  Sys.println("an uncaught String is reported with its text: "+thrownString.lines.contains("Error : thrown"));
 }
}
