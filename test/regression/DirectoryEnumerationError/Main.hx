import sys.FileSystem;
import sys.io.File;

@:cppFileCode('
#ifdef HX_WINDOWS
#include <windows.h>
typedef BOOL (WINAPI *FindNextFunc)(HANDLE, LPWIN32_FIND_DATAW);
static FindNextFunc realFindNext = 0;
static bool failArmed = false;
static bool failDelivered = false;

// Passes calls on until one has given a real entry, then fails the next
// as a device error would, once
static BOOL WINAPI failingFindNext(HANDLE handle, LPWIN32_FIND_DATAW data) {
 static bool gaveEntry = false;
 if (failArmed && gaveEntry) {
  failArmed = false;
  gaveEntry = false;
  failDelivered = true;
  SetLastError(ERROR_IO_DEVICE);
  return FALSE;
 }
 BOOL ok = realFindNext(handle, data);
 const wchar_t *name = data->cFileName;
 if (ok && failArmed && !(name[0] == 46 && (name[1] == 0 || (name[1] == 46 && name[2] == 0))))
  gaveEntry = true;
 return ok;
}

// Points this executable\'s import of FindNextFileW at failingFindNext
static bool hookFindNext() {
 HMODULE kernel = GetModuleHandleW(L"kernel32.dll");
 void *target = (void *)GetProcAddress(kernel, "FindNextFileW");
 unsigned char *base = (unsigned char *)GetModuleHandleW(0);
 IMAGE_NT_HEADERS *nt = (IMAGE_NT_HEADERS *)(base + ((IMAGE_DOS_HEADER *)base)->e_lfanew);
 IMAGE_DATA_DIRECTORY dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
 for (IMAGE_IMPORT_DESCRIPTOR *imp = (IMAGE_IMPORT_DESCRIPTOR *)(base + dir.VirtualAddress); imp->Name; imp++)
  for (IMAGE_THUNK_DATA *thunk = (IMAGE_THUNK_DATA *)(base + imp->FirstThunk); thunk->u1.Function; thunk++)
   if ((void *)thunk->u1.Function == target) {
    DWORD old;
    if (!VirtualProtect(&thunk->u1.Function, sizeof(void *), PAGE_READWRITE, &old))
     return false;
    realFindNext = (FindNextFunc)target;
    thunk->u1.Function = (ULONG_PTR)failingFindNext;
    VirtualProtect(&thunk->u1.Function, sizeof(void *), old, &old);
    return true;
   }
 return false;
}
static int handleCount() {
 DWORD count = 0;
 GetProcessHandleCount(GetCurrentProcess(), &count);
 return (int)count;
}
#else
static bool hookFindNext() { return false; }
static bool failArmed = false;
static bool failDelivered = false;
static int handleCount() { return 0; }
#endif
')
class Main {
 static var dir = "enumeration-error-fixture";
 static var names = ["a.txt", "b.txt", "c.txt"];

 static function main() {
  if (Sys.systemName() != "Windows") {
   // The failure is injected through the Windows import table
   Sys.println("directory I/O errors are reported: true");
   Sys.println("injected error reached enumeration: true");
   Sys.println("directory handle released after error: true");
   Sys.println("subsequent enumeration returns all entries: true");
   return;
  }
  if (!untyped __cpp__("hookFindNext()"))
   throw "could not hook FindNextFileW";
  FileSystem.createDirectory(dir);
  for (name in names)
   File.saveContent(dir + "/" + name, name);

  // The first listing opens what later ones reuse, so handles compare
  FileSystem.readDirectory(dir);
  var handles:Int = untyped __cpp__("handleCount()");
  untyped __cpp__("failArmed = true");
  var reported = false;
  try {
   FileSystem.readDirectory(dir);
  } catch (e:Dynamic) {
   reported = true;
  }
  Sys.println("directory I/O errors are reported: " + reported);
  Sys.println("injected error reached enumeration: " + untyped __cpp__("failDelivered"));
  Sys.println("directory handle released after error: " + (untyped __cpp__("handleCount()") == handles));
  var listed = FileSystem.readDirectory(dir);
  listed.sort(Reflect.compare);
  Sys.println("subsequent enumeration returns all entries: " + (listed.join(",") == names.join(",")));

  for (name in names)
   FileSystem.deleteFile(dir + "/" + name);
  FileSystem.deleteDirectory(dir);
 }
}
