// Compiled cppia code keeps a pending exception in StackContext::exception,
// where 0 means there is none. A null the script threw was lost once it left
// the function that threw it, so the caller carried on, and a null the host
// threw into compiled script code became an empty String, which
// catch (s:String) caught. A thrown null now stays null under the JIT, as it
// does interpreted and in compiled code.
function main() {
	// Builds Native into the host
	Native.pass(() -> {});
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	for (jit in [false, true]) {
		cpp.cppia.Host.enableJit(jit);
		try {
			cpp.cppia.Host.runFile(script);
		} catch (e:Dynamic) {
			Sys.println("host caught " + (e == null ? "null" : "'" + e + "'"));
		}
	}
}
