import sys.FileSystem;

// Only Linux allows a current directory longer than 1024 characters without opting in
function main() {
	if (Sys.systemName() != "Linux") {
		Sys.println(Sys.getCwd() != null ? "long cwd ok" : "no cwd");
		return;
	}
	final base = Sys.getCwd();
	final root = haxe.io.Path.directory(Sys.programPath()) + "/longcwd";
	final seg = [for (i in 0...200) "d"].join("");
	var deep = root;
	for (i in 0...6)
		deep += "/" + seg;
	FileSystem.createDirectory(deep);
	Sys.setCwd(deep);
	final cwd = Sys.getCwd();
	Sys.setCwd(base);
	var dir = deep;
	while (dir.length >= root.length) {
		FileSystem.deleteDirectory(dir);
		dir = haxe.io.Path.directory(dir);
	}
	Sys.println(cwd != null && cwd.length > 1200 && StringTools.endsWith(cwd, seg + "/") ? "long cwd ok" : 'long cwd $cwd');
}
