import sys.FileSystem;

function main() {
	var args = Sys.args();
	if (args.length == 2 && args[0] == "child") {
		var inherited = false;
		for (fd in FileSystem.readDirectory("/proc/self/fd"))
			try {
				if (FileSystem.fullPath("/proc/self/fd/" + fd) == args[1])
					inherited = true;
			} catch (_:Dynamic) {}
		Sys.print(inherited ? "inherited" : "not inherited");
		return;
	}
	if (Sys.systemName() != "Linux") {
		Sys.println("written file: not inherited");
		Sys.println("read file: not inherited");
		return;
	}
	var marker = FileSystem.fullPath(haxe.io.Path.directory(Sys.programPath())) + "/marker.txt";
	var out = sys.io.File.write(marker);
	Sys.println("written file: " + child(marker));
	out.close();
	var input = sys.io.File.read(marker);
	Sys.println("read file: " + child(marker));
	input.close();
	FileSystem.deleteFile(marker);
}

function child(marker:String):String {
	var p = new sys.io.Process(Sys.programPath(), ["child", marker]);
	var result = p.stdout.readAll().toString();
	p.close();
	return result;
}
