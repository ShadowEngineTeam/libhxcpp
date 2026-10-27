import sys.io.File;
import sys.io.FileSeek;

class Main {
 static var path = "text-checkpoint.tmp";

 // The checkpoint after one byte read with readByte, and with readBytes,
 // and the bytes that seeking back to each one reads next
 static function check(binary:Bool, label:String) {
  var input = File.read(path, binary);
  input.readByte();
  var byteCheckpoint = input.tell();
  input.seek(byteCheckpoint, SeekBegin);
  var byteNext = input.readByte();
  input.close();

  input = File.read(path, binary);
  input.readBytes(haxe.io.Bytes.alloc(1), 0, 1);
  var bulkCheckpoint = input.tell();
  input.seek(bulkCheckpoint, SeekBegin);
  var bulkNext = input.readByte();
  input.close();

  Sys.println('$label checkpoint matches bulk-read control: ' + (byteCheckpoint == bulkCheckpoint));
  Sys.println('$label checkpoint restores next byte: ' + (byteNext == bulkNext));
 }

 static function main() {
  File.saveBytes(path, haxe.io.Bytes.ofString("a\r\nb\r\nc"));
  check(false, "text-mode");
  check(true, "binary-mode");
  // Text mode still reads every translated byte with readByte
  var input = File.read(path, false);
  var all = new StringBuf();
  try while (true) all.addChar(input.readByte()) catch (e:haxe.io.Eof) {}
  input.close();
  var expected = Sys.systemName() == "Windows" ? "a\nb\nc" : "a\r\nb\r\nc";
  Sys.println("text-mode readByte reads the whole file: " + (all.toString() == expected));
  sys.FileSystem.deleteFile(path);
 }
}
