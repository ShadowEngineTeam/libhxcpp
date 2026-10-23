import cpp.vm.Debugger;

// A debugger learns of each script as it loads, before the script boots, so it
// can set breakpoints in files that were not there when it attached. The
// callback exists at every API level, not only at 500.
class Main {
	static var calls = 0;
	static var known = false;

	static function main() {
		var onLoaded:Dynamic = function() {
			calls++;
			known = Lambda.exists(Debugger.getFiles(), f -> StringTools.endsWith(f, "Script.hx"));
		};
		untyped __cpp__("\n#ifndef HXCPP_DBG_ON_SCRIPT_LOADED\n#error HXCPP_DBG_ON_SCRIPT_LOADED is not defined\n#endif\n");
		untyped __global__.__hxcpp_dbg_setOnScriptLoadedFunction(onLoaded);

		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var module = cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		Sys.println('loaded: the callback ran $calls time, Script.hx known $known');
		module.boot();
		module.run();
	}
}
