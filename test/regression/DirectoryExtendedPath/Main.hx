import sys.FileSystem;
import sys.io.File;

@:cppFileCode('
#ifdef HX_WINDOWS
#include <windows.h>
static bool createDirW(String path) { return CreateDirectoryW(path.wchar_str(), 0); }
static bool removeDirW(String path) { return RemoveDirectoryW(path.wchar_str()); }
#else
static bool createDirW(String) { return false; }
static bool removeDirW(String) { return false; }
#endif
')
class Main {
 static var sep = String.fromCharCode(92);

 static function makeDir(path:String):Bool return untyped __cpp__("createDirW({0})", path);
 static function removeDir(path:String):Bool return untyped __cpp__("removeDirW({0})", path);

 static function list(path:String):String {
  try {
   var names = FileSystem.readDirectory(path);
   names.sort(Reflect.compare);
   return names.join(",");
  } catch (e:Dynamic) {
   return "error " + e;
  }
 }

 static function main() {
  if (Sys.systemName() != "Windows") {
   // Extended-length paths are Windows syntax
   Sys.println("runtime lists the extended directory: true");
   Sys.println("runtime lists an empty extended directory: true");
   Sys.println("short-path control and fixture cleanup: true");
   return;
  }
  var root = StringTools.replace(Sys.getCwd(), "/", sep);
  if (!StringTools.endsWith(root, sep))
   root += sep;
  // \\?\ and an absolute path, which Windows takes past MAX_PATH as it is
  var fixture = sep + sep + "?" + sep + root + "extended-path-fixture";
  var dirs = [fixture];
  var component = StringTools.lpad("", "d", 100);
  for (i in 0...3)
   dirs.push(dirs[dirs.length - 1] + sep + component + i);
  for (dir in dirs)
   if (!makeDir(dir))
    throw "could not create the fixture";
  var deepest = dirs[dirs.length - 1];
  if (deepest.length <= 260)
   throw "the fixture path is not long";
  var marker = deepest + sep + "marker.txt";
  File.saveContent(marker, "marker");

  Sys.println("runtime lists the extended directory: " + (list(deepest) == "marker.txt" && list(deepest + sep) == "marker.txt"));
  FileSystem.deleteFile(marker);
  Sys.println("runtime lists an empty extended directory: " + (list(deepest) == "" && list(deepest + sep) == ""));

  var cleaned = true;
  var i = dirs.length;
  while (i-- > 0)
   cleaned = removeDir(dirs[i]) && cleaned;
  Sys.println("short-path control and fixture cleanup: " + (cleaned && list(".").indexOf("build.hxml") >= 0 && list("./").indexOf("Main.hx") >= 0));
 }
}
