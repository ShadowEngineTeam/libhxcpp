import sys.FileSystem;
import sys.io.File;

function main() {
	final path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "ctime.txt"]);
	File.saveContent(path, "a");
	final created = FileSystem.stat(path).ctime.getTime();
	Sys.sleep(1.5);
	// Growing the file changes its status change time, not when it was created
	final out = File.append(path);
	out.writeString("b");
	out.close();
	Sys.println(FileSystem.stat(path).ctime.getTime() == created);
	FileSystem.deleteFile(path);
}
