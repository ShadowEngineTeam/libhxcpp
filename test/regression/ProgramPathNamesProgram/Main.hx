import haxe.io.Path;
import sys.FileSystem;

// Run.hx starts this from test/regression, so the path has to come back
// absolute to name this program wherever it runs from. Under node the
// program is bin/Main.js, not node
function main() {
	var path = Sys.programPath();
	Sys.println("program path is absolute: " + (path != null && Path.isAbsolute(path)));
	Sys.println("program path is a file: " + (path != null && FileSystem.exists(path) && !FileSystem.isDirectory(path)));
	Sys.println("program is named Main: " + (path != null && StringTools.startsWith(Path.withoutDirectory(path), "Main")));
	var dir = path == null ? "" : Path.directory(path);
	Sys.println("program is in the test's bin: " + (Path.withoutDirectory(dir) == "bin" && FileSystem.exists(Path.join([dir, "..", "build.hxml"]))));
}
