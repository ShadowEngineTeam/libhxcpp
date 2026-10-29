// An abstract function comes in a cppia file with a bare RETURN as its body,
// which is never run. It was kept as a function through a cast, which is
// undefined for an expression that is not one; it has no function now, and
// its class's subclasses still dispatch to their overrides.
function main() {
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	for (jit in [false, true]) {
		cpp.cppia.Host.enableJit(jit);
		try {
			cpp.cppia.Host.runFile(script);
		} catch (e:Dynamic) {
			Sys.println("error: " + e);
		}
	}
}
