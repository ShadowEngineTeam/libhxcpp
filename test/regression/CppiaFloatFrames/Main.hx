// cppia stores a Float in a frame with SetFloatAligned. On 32-bit ARM and
// Emscripten (HXCPP_ALIGN_FLOAT) it wrote only the high half of the double,
// so arguments, locals and results that cross a frame lost their low bits.
// It now copies the whole value the same way on every target, so this test,
// which passes values whose low bits matter in each direction, covers the
// code those targets run.
function main() {
	var script = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
	for (jit in [false, true]) {
		cpp.cppia.Host.enableJit(jit);
		try {
			cpp.cppia.Host.runFile(script);
			Sys.println("script from host: " + Host.fromScript(1, 3) + " " + Host.fromScript(2, 7));
		} catch (e:Dynamic) {
			Sys.println("error: " + e);
		}
	}
}
