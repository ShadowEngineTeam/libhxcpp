function main() {
	try {
		var s = sys.FileSystem.stat("no-such-dir/no-such-file");
		Sys.println("returned mtime " + s.mtime.getTime());
	} catch (e:Dynamic) {
		Sys.println("threw");
	}
	var self = sys.FileSystem.stat(Sys.programPath());
	Sys.println(self.size > 0 && self.mtime.getTime() > 0 ? "existing file stats" : "bad stats");
}
