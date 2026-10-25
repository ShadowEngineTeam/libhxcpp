@:cppFileCode('
#ifdef HX_WINDOWS
#include <windows.h>
#include <sys/stat.h>
#else
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#endif
static bool setFixtureTime(String path,double seconds) {
#ifdef HX_WINDOWS
 HANDLE file=CreateFileW(path.wchar_str(),FILE_WRITE_ATTRIBUTES,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
 if(file==INVALID_HANDLE_VALUE) return false;
 ULARGE_INTEGER ticks; ticks.QuadPart=(ULONGLONG)((seconds+11644473600.0)*10000000.0);
 FILETIME time; time.dwLowDateTime=ticks.LowPart; time.dwHighDateTime=ticks.HighPart;
 bool ok=SetFileTime(file,&time,&time,&time)!=0;
 CloseHandle(file); return ok;
#else
 timespec times[2]={{(time_t)seconds,0},{(time_t)seconds,0}};
 return utimensat(AT_FDCWD,path.utf8_str(),times,0)==0;
#endif
}
static double nativeFixtureTime(String path) {
#ifdef HX_WINDOWS
 struct _stat64 info={};
 if(_wstat64(path.wchar_str(),&info)!=0) return -1;
#else
 struct stat info={};
 if(stat(path.utf8_str(),&info)!=0) return -1;
#endif
 return (double)info.st_mtime;
}
')
class Main {
 static function main() {
  var path="future-stat-"+Std.random(1000000000)+".tmp";
  if(sys.FileSystem.exists(path)) throw "Fixture already exists";
  sys.io.File.saveContent(path,"metadata fixture");
  try {
   var ordinary=946684800.0;
   if(!(untyped __cpp__("setFixtureTime({0},{1})",path,ordinary))) throw "set time";
   var control=sys.FileSystem.stat(path);
   Sys.println("ordinary file timestamps remain correct: "+(control.mtime.getTime()==ordinary*1000 && control.atime.getTime()==ordinary*1000));
   // Where time_t is 32 bits, as on 32-bit Linux, no file can have a 2040
   // time, so there is nothing for stat to keep
   var timeBits:Int=untyped __cpp__("(int)(sizeof(time_t)*8)");
   if(timeBits<64) {
    for(line in ["native metadata preserves a 2040 timestamp","FileStat preserves the future modification time","FileStat preserves the future access time"])
     Sys.println(line+": true");
    sys.FileSystem.deleteFile(path);
    return;
   }
   var future=2208988800.0;
   if(!(untyped __cpp__("setFixtureTime({0},{1})",path,future))) throw "set future time";
   var nativeTime:Float=untyped __cpp__("nativeFixtureTime({0})",path);
   var actual=sys.FileSystem.stat(path);
   Sys.println("native metadata preserves a 2040 timestamp: "+(nativeTime==future));
   Sys.println("FileStat preserves the future modification time: "+(actual.mtime.getTime()==future*1000));
   Sys.println("FileStat preserves the future access time: "+(actual.atime.getTime()==future*1000));
   if(Sys.getEnv("SHOW_TIME")!=null) Sys.println("expected="+(future*1000)+" actual="+actual.mtime.getTime());
  } catch(e:Dynamic) { sys.FileSystem.deleteFile(path); throw e; }
  sys.FileSystem.deleteFile(path);
 }
}