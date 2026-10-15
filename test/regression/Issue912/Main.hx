function main() {
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	try {
		cpp.cppia.Host.runFile(script);
		ToolCore.replaceable_func();
	} catch (e:Dynamic) {
		Sys.println("error: " + e);
	}
}
