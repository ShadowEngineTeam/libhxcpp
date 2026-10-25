class Main {
	static function main() {
		var path = "zero-read-" + Std.string(Date.now().getTime()) + ".tmp";
		sys.io.File.saveContent(path, "a");
		var input = sys.io.File.read(path);
		if (input.readByte() != 97) throw "Unexpected fixture content";
		var before = input.eof();
		var empty = haxe.io.Bytes.alloc(0);
		var got = input.readBytes(empty, 0, 0);
		var after = input.eof();
		Sys.println("zero bytes returned: " + (got == 0));
		Sys.println("empty backing buffer preserved: " + (empty.getData().length == 0));
		Sys.println("EOF state preserved: " + (after == before));
		Sys.println("position preserved: " + (input.tell() == 1));
		input.close();
		sys.FileSystem.deleteFile(path);
	}
}
