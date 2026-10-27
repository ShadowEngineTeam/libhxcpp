Draft issue for HaxeFoundation/haxe (not posted)

Title: [cpp] Generated file names for generic instances pass the Windows path limit

Labels: platform-cpp

A C++ build on Windows fails when the output folder is deep and a `@:generic` class is instantiated with a type from a deep package. The generated name repeats the parameter's whole path, and the generator writes it under the class's package folders, so the package appears twice:

```
src/app/internal/system/timer/TimerTable_app_internal_system_timer_wheel__TimerWheel_WheelNode.cpp
```

From an output folder of 159 characters the header path reaches 260 and haxe.exe stops with `Sys_error(... No such file or directory)` (also #11714, haxe.exe has no `longPathAware` manifest). Making haxe.exe long path aware is not enough: MSVC's cl.exe, c1xx.dll and link.exe are not long path aware either, and cl.exe cannot read headers through a `\?\` include directory, so the compile fails with C1083 instead. The libhxcpp build tool now warns about this and shortens its own object names (openfl/libhxcpp#356), but it cannot rename the generated sources and headers, which the generated `#include` lines name.

Proposal: an opt-in define, for example `-D cpp_max_file_name=40`. When a class's file base name is longer than that, the generator writes its files as the first N characters, an underscore and 8 hex digits of the MD5 of the dotted class path (`TimerTable_52e02d87.h`). Only file names change; C++ class names, include guards, reflection and stack traces stay the same. The name depends only on the class path, so it is stable between runs and machines, and the generator reports an error if two class paths in one run map to the same file.

In 4.3.x the file names come from `new_source_file`, `add_include`, `write_build_data` and the `@:nativeGen` header include in the dependency collector in `src/generators/gencpp.ml`; in development from `src/generators/cpp/cppSourceWriter.ml`. One helper used in those places keeps the files, the includes and Build.xml in step.

Checked by hand: renaming the long instance's .cpp and .h to `TimerTable_52e02d87` and updating the includes and Build.xml, the repro below builds and runs with MSVC from a 182 character output folder; without the rename it fails from 159.

Repro: the three files in openfl/libhxcpp#356, then

```
haxe -cp src -main Main -cpp C:/lp/<150 x characters>/cpp
```
