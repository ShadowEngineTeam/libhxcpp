Long paths on Windows
---------------------
MSVC cannot open a file whose full path reaches 260 characters. `cl.exe`, `c1xx.dll` and `link.exe` are not long path aware, so turning on `LongPathsEnabled` in the registry does not help them, and `cl.exe` does not find headers through a `\?\` include directory. It reports such a file as missing:

```
fatal error C1083: Cannot open source file: './src/app/internal/system/timer/TimerTable_app_internal_system_timer_wheel__TimerWheel_WheelNode.cpp': No such file or directory
```

Haxe 4.3 stops earlier, while writing the generated C++, since `haxe.exe` is not long path aware either (HaxeFoundation/haxe#11714):

```
Sys_error("<output>/include/app/internal/system/timer/TimerTable_app_internal_system_timer_wheel__TimerWheel_WheelNode.h: No such file or directory")
```

Generated paths get long fastest with a `@:generic` class, because Haxe names each instance after its parameter's whole path and writes it under the class's own package folders: `TimerTable<app.internal.system.timer.wheel.TimerWheel.WheelNode>` becomes `src/app/internal/system/timer/TimerTable_app_internal_system_timer_wheel__TimerWheel_WheelNode.cpp`.

### Working around it
Build through a short path that points to the project:

```
mklink /J C:\b C:\a\very\deep\project\folder
cd /d C:\b
haxe build.hxml
```

`subst B: C:\a\very\deep\project\folder` works the same way. Haxe, the build tool and MSVC then only see the short paths. Removing the junction with `rmdir C:\b` leaves the project folder alone.

A shorter package for the generic parameter, or a shorter output folder, also works.

### What the build tool does
- Object files are written flat under `obj/`, named after the source file. A source file name longer than 48 characters is cut to 39 and followed by 8 hex digits of its MD5, so the object path does not reach the limit before the source does.
- When a build with `cl.exe` has a source, a generated header beside it or an object path of 260 characters or more, it warns before compiling, naming the longest one and the workaround above. `clang-cl` (`HXCPP_MSVC_LLVM`) handles long paths itself and gets no warning.

### What only Haxe can fix
The build tool compiles the files Haxe names, and the `#include` lines in the generated code name them too, so shorter generated file names have to come from the Haxe C++ generator. libhxcpp #356 proposes a define there that writes a long class's files as a cut name plus a hash of its class path, keeping C++ class names, include guards and reflection as they are. A long path aware `haxe.exe` alone moves the failure to MSVC.
