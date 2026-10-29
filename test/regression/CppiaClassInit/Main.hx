// A class's __init__ comes in a cppia file as an expression of any kind,
// which the class runs as it is, not as a function. Loading refused any
// function body that was not a function or an abstract function's RETURN,
// so a script with a class __init__ failed to load with "Function body is
// not a function".
function main() {
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	try {
		cpp.cppia.Host.runFile(script);
	} catch (e:Dynamic) {
		Sys.println("error: " + e);
	}
}
