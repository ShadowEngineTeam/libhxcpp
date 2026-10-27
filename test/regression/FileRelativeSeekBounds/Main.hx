import sys.io.File;
import sys.io.FileInput;
import sys.io.FileSeek;

class Main {
 static var path = "relative-seek.tmp";

 // Seeks back by -2147483648 from position 1, before the start of the file
 static function rejectsLargeBackwardSeek(input:FileInput):Bool {
  try {
   input.seek(-2147483648, SeekCur);
   return false;
  } catch (e:Dynamic) {
   return true;
  }
 }

 static function main() {
  var data = haxe.io.Bytes.alloc(8192);
  for (i in 0...data.length)
   data.set(i, i & 0xff);
  File.saveBytes(path, data);

  var input = File.read(path, true);
  input.readByte();
  var rejected = rejectsLargeBackwardSeek(input);
  Sys.println("large negative seek after readByte is rejected: " + rejected);
  // The failed seek leaves the file where it was
  var kept = false;
  try kept = input.tell() == 1 && input.readByte() == 1 catch (e:Dynamic) {}
  Sys.println("rejected seek keeps the position: " + kept);
  input.close();

  input = File.read(path, true);
  input.readBytes(haxe.io.Bytes.alloc(1), 0, 1);
  Sys.println("large negative seek after readBytes is rejected: " + rejectsLargeBackwardSeek(input));
  input.close();

  input = File.read(path, true);
  for (i in 0...10)
   input.readByte();
  input.seek(-4, SeekCur);
  var valid = input.tell() == 6 && input.readByte() == 6;
  input.seek(100, SeekCur);
  valid = valid && input.tell() == 107 && input.readByte() == 107;
  Sys.println("valid relative seek preserves byte and position: " + valid);
  input.close();

  sys.FileSystem.deleteFile(path);
 }
}
