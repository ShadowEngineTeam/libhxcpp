import sys.FileSystem;
import sys.io.File;

@:cppFileCode('
#ifdef HX_WINDOWS
#include <windows.h>
#include <vector>
#include <string>
static bool createDirW(String path) { return CreateDirectoryW(path.wchar_str(), 0); }
static bool removeDirW(String path) { return RemoveDirectoryW(path.wchar_str()); }
static bool copyFileW(String from, String to) { return CopyFileW(from.wchar_str(), to.wchar_str(), TRUE); }
static bool deleteFileW(String path) { return DeleteFileW(path.wchar_str()); }
// The executable path, from a buffer big enough for any
static String moduleFileName() {
 std::vector<wchar_t> path(32768);
 DWORD len = GetModuleFileNameW(NULL, &path[0], (DWORD)path.size());
 if (len == 0 || len >= path.size())
  return String();
 return String::create(&path[0], len);
}
// Runs exe with args and returns its exit code, or -1 if it did not start
static int runW(String exe, String args) {
 std::wstring command = std::wstring(L"\\"") + exe.wchar_str() + L"\\" " + args.wchar_str();
 STARTUPINFOW startup = { sizeof(startup) };
 PROCESS_INFORMATION info;
 if (!CreateProcessW(exe.wchar_str(), &command[0], 0, 0, FALSE, 0, 0, 0, &startup, &info))
  return -1;
 hx::EnterGCFreeZone();
 WaitForSingleObject(info.hProcess, INFINITE);
 hx::ExitGCFreeZone();
 DWORD code = 0;
 GetExitCodeProcess(info.hProcess, &code);
 CloseHandle(info.hProcess);
 CloseHandle(info.hThread);
 return (int)code;
}
#else
static bool createDirW(String) { return false; }
static bool removeDirW(String) { return false; }
static bool copyFileW(String, String) { return false; }
static bool deleteFileW(String) { return false; }
static String moduleFileName() { return String(); }
static int runW(String, String) { return -1; }
#endif
')
class Main {
 static var sep = String.fromCharCode(92);

 static function makeDir(path:String):Bool return untyped __cpp__("createDirW({0})", path);
 static function removeDir(path:String):Bool return untyped __cpp__("removeDirW({0})", path);
 static function copy(from:String, to:String):Bool return untyped __cpp__("copyFileW({0}, {1})", from, to);
 static function delete(path:String):Bool return untyped __cpp__("deleteFileW({0})", path);
 static function nativePath():String return untyped __cpp__("moduleFileName()");
 static function run(exe:String, args:String):Int return untyped __cpp__("runW({0}, {1})", exe, args);

 static function main() {
  var args = Sys.args();
  if (args.length == 2 && args[0] == "child") {
   // The copy in the long directory: report what each query says
   File.saveContent(args[1], (Sys.programPath() == nativePath()) + " " + (nativePath().length > 260));
   return;
  }
  if (Sys.systemName() != "Windows") {
   // Extended-length paths are Windows syntax
   Sys.println("short executable path matches native query: true");
   Sys.println("long-path executable starts and exits normally: true");
   Sys.println("runtime reports the complete long executable path: true");
   Sys.println("executable fixture cleanup: true");
   return;
  }
  Sys.println("short executable path matches native query: " + (Sys.programPath() == nativePath()));

  var root = StringTools.replace(Sys.getCwd(), "/", sep);
  if (!StringTools.endsWith(root, sep))
   root += sep;
  var fixture = root + "extended-exe-fixture";
  // \\?\ and an absolute path, which Windows takes past MAX_PATH as it is
  var dirs = [sep + sep + "?" + sep + fixture];
  var component = StringTools.lpad("", "d", 100);
  for (i in 0...3)
   dirs.push(dirs[dirs.length - 1] + sep + component + i);
  for (dir in dirs)
   if (!makeDir(dir))
    throw "could not create the fixture";
  var exe = dirs[dirs.length - 1] + sep + "Main.exe";
  if (!copy(nativePath(), exe))
   throw "could not copy the executable";
  var report = fixture + sep + "report.txt";

  var code = run(exe, "child \"" + report + "\"");
  Sys.println("long-path executable starts and exits normally: " + (code == 0));
  var result = FileSystem.exists(report) ? File.getContent(report) : "";
  Sys.println("runtime reports the complete long executable path: " + (result == "true true"));

  var cleaned = (!FileSystem.exists(report) || delete(report)) && delete(exe);
  var i = dirs.length;
  while (i-- > 0)
   cleaned = removeDir(dirs[i]) && cleaned;
  Sys.println("executable fixture cleanup: " + cleaned);
 }
}
