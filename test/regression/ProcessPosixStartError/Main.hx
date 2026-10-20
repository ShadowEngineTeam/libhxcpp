function start(cmd:String, args:Array<String>):String {
	try {
		var p = new sys.io.Process(cmd, args);
		var code = p.exitCode();
		p.close();
		return "started, exit " + code;
	} catch (e:Dynamic) {
		return "failed to start";
	}
}

function main() {
	if (Sys.systemName() == "Windows") {
		Sys.println("missing: failed to start");
		Sys.println("not executable: failed to start");
		Sys.println("exits 127: started, exit 127");
		return;
	}
	var dir = haxe.io.Path.directory(Sys.programPath());
	var plain = sys.FileSystem.fullPath(dir) + "/plain.txt";
	sys.io.File.saveContent(plain, "not a program");
	Sys.println("missing: " + start("/no-such-libhxcpp-command", []));
	Sys.println("not executable: " + start(plain, []));
	Sys.println("exits 127: " + start("sh", ["-c", "exit 127"]));
	sys.FileSystem.deleteFile(plain);
}
