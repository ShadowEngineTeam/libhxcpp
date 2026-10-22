import cpp.vm.Debugger;
import sys.thread.Deque;
import sys.thread.Thread;

// A debugger thread stops a script at a breakpoint, reads its variables, steps
// over, out and in, and continues, once interpreted and once jitted.
class Main {
	static var events = new Deque<Array<Dynamic>>();
	static var log:Array<String> = [];

	static function onEvent(threadNumber:Int, event:Int, ?stackFrame:Int, ?className:String, ?functionName:String, ?fileName:String,
			?lineNumber:Int) {
		if (event == Debugger.THREAD_STOPPED)
			events.add([threadNumber, functionName, fileName, lineNumber, stackFrame]);
	}

	// The event gives the stack depth; frames count up from the outermost
	static function variables(thread:Int, depth:Int):String {
		var frame = depth - 1;
		var names = Debugger.getStackVariables(thread, frame, false);
		names.sort(Reflect.compare);
		return [for (n in names) n + "=" + Std.string(Debugger.getStackVariableValue(thread, frame, n, false))].join(" ");
	}

	// Each stop: where it is, its locals, then the next action
	static function debugger(steps:Array<Int>, done:Deque<Bool>) {
		Debugger.setEventNotificationHandler(onEvent);
		done.add(true);
		while (true) {
			var e = events.pop(true);
			if (e[0] == null)
				break;
			var thread:Int = e[0];
			var file = haxe.io.Path.withoutDirectory(e[2]);
			log.push('stop ${e[1]} $file:${e[3]} ${variables(thread, e[4])}');
			// Change a local while stopped: the script must go on with the new value
			if (e[3] == 4) {
				Debugger.setStackVariableValue(thread, (e[4] : Int) - 1, "sum", 7, false);
				log.push('set sum=7');
			}
			var step = steps.shift();
			if (step == null)
				Debugger.continueThreads(-1, 1);
			else
				Debugger.stepThread(thread, step);
		}
		done.add(true);
	}

	static function main() {
		Debugger.enableCurrentThreadDebugging(true);
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			log = [];
			var done = new Deque<Bool>();
			var steps = [Debugger.STEP_OVER, Debugger.STEP_OVER, Debugger.STEP_OUT, Debugger.STEP_INTO];
			Thread.create(() -> debugger(steps, done));
			done.pop(true);

			var module = cpp.cppia.Module.fromData(bytes.getData());
			var file = [for (f in Debugger.getFiles()) if (StringTools.endsWith(f, "Script.hx")) f][0];
			var breakpoint = Debugger.addFileLineBreakpoint(file, 3);
			module.boot();
			module.run();
			Debugger.deleteBreakpoint(breakpoint);

			// Breaking on a function by name stops at its first line
			var byName = Debugger.addClassFunctionBreakpoint("Script", "add");
			log.push("run again with a breakpoint on Script.add" + (byName < 0 ? ": not set" : ""));
			module.run();
			Debugger.deleteBreakpoint(byName);

			events.add([null]);
			done.pop(true);
			Sys.println((jit ? "jit" : "interpreter") + (breakpoint < 0 ? ": breakpoint not set" : ""));
			for (line in log)
				Sys.println("  " + line);
			untyped module.release();
		}
	}
}
