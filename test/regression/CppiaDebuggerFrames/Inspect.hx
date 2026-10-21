import cpp.vm.Debugger;

class Inspect {
	public static function caller(name:String):String {
		var thread = Debugger.getCurrentThreadNumber();
		var stack = Debugger.getThreadInfo(thread, true).stack;
		for (i in 0...stack.length)
			if (stack[i].functionName == name) {
				var names = Debugger.getStackVariables(thread, i, true);
				names.sort(Reflect.compare);
				var values = [for (n in names) n == "this" ? "this=" + Std.string(Debugger.getStackVariableValue(thread, i, n, true) != null)
					: n + "=" + Std.string(Debugger.getStackVariableValue(thread, i, n, true))];
				return values.join(" ");
			}
		return "no frame for " + name;
	}
}
