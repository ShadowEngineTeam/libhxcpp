import cpp.NativeFile;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

// file_open with "x" in its mode must fail on a file that exists. On POSIX the
// runtime opens files with open(2), to make them close-on-exec, and mapped
// the mode without O_EXCL, so "wbx" truncated the file (libhxcpp #391)
class Main {
	static function opens(path:String, mode:String, ?text:String):Bool {
		try {
			var handle = NativeFile.file_open(path, mode);
			if (text != null)
				NativeFile.file_write(handle, haxe.io.Bytes.ofString(text).getData(), 0, text.length);
			NativeFile.file_close(handle);
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	static function main() {
		var dir = Path.directory(Sys.programPath());
		var existing = Path.join([dir, "exclusive-existing.txt"]);
		var fresh = Path.join([dir, "exclusive-fresh.txt"]);
		for (path in [existing, fresh])
			if (FileSystem.exists(path))
				FileSystem.deleteFile(path);

		File.saveContent(existing, "keep this payload");
		var refused = !opens(existing, "wbx");
		var refusedUpdate = !opens(existing, "w+bx");
		var unchanged = File.getContent(existing) == "keep this payload";
		if (!unchanged)
			Sys.stderr().writeString('contents now "${File.getContent(existing)}"\n');

		var created = opens(fresh, "wbx", "new file");
		var written = created && File.getContent(fresh) == "new file";

		// x only goes with w: C11 leaves the rest undefined, and open(2) with
		// O_EXCL but not O_CREAT is too
		var mixed = true;
		if (Sys.systemName() != "Windows") {
			for (mode in ["rbx", "abx"])
				if (opens(existing, mode)) {
					Sys.stderr().writeString('$mode opened\n');
					mixed = false;
				}
			mixed = mixed && File.getContent(existing) == "keep this payload";
		}

		for (path in [existing, fresh])
			if (FileSystem.exists(path))
				FileSystem.deleteFile(path);

		Sys.println("exclusive creation refuses an existing file: " + (refused && refusedUpdate));
		Sys.println("failed exclusive creation preserves existing contents: " + unchanged);
		Sys.println("exclusive creation makes a new file: " + written);
		Sys.println("exclusive mode without w is refused: " + mixed);
	}
}
