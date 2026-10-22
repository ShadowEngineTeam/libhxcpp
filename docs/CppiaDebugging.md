# Debugging cppia scripts

Script code can be debugged like native code: breakpoints by file and line or by function, stepping into, over and out of functions (including from a script into host code), and reading and changing a frame's `this`, arguments and locals. This works the same in the interpreter and with the JIT.

## What it needs

- **The host is built with `-D HXCPP_DEBUGGER`**, which also turns on stack lines, so every script line can reach the debugger.
- **The script is compiled with `-debug`.** Without it the `.cppia` file carries no source file names: the script's code shows up under a file called `?`, and a breakpoint in it cannot be set.
- **Each thread to be debugged calls `cpp.vm.Debugger.enableCurrentThreadDebugging(true)`.** A thread that has not done so never stops. Debugger front ends such as hxcpp-debug-server do this for the threads they debug.

## How a debugger drives it

The debugger runs on its own thread, which never stops, and registers a handler with `cpp.vm.Debugger.setEventNotificationHandler`. When a thread stops, it calls that handler on its own stack with `THREAD_STOPPED`, then waits until the debugger continues or steps it.

A script's files are known to the debugger once the module has loaded (`cpp.cppia.Module.fromData`), so add breakpoints in it after loading and before running it:

```haxe
var module = cpp.cppia.Module.fromData(bytes.getData());
var breakpoint = cpp.vm.Debugger.addFileLineBreakpoint("Script.hx", 12);
module.boot();
module.run();
```

A breakpoint names the file as the script was compiled; `cpp.vm.Debugger.getFiles()` lists the names it knows.

In the stop event, the stack frame argument is the thread's stack depth. Stack frames are numbered from the outermost, so the frame that stopped is `depth - 1` in `getStackVariables`, `getStackVariableValue` and `setStackVariableValue`.

`test/regression/CppiaBreakpoints` drives a script this way: it stops at a breakpoint, reads and changes locals, steps over, out and in, and breaks on a function by name, in both the interpreter and the JIT.

## Limitations

- Profiler and telemetry builds keep released modules, as described in [CppiaModuleRelease.md](CppiaModuleRelease.md).
