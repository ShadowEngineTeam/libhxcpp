function main() {
	if (Sys.systemName() != "Linux") {
		Sys.println("caught");
		return;
	}
	try {
		var out = sys.io.File.write("/dev/full");
		out.writeBytes(haxe.io.Bytes.alloc(100000), 0, 100000);
		out.close();
		Sys.println("no error");
	} catch (e:Dynamic) {
		Sys.println("caught");
	}
}
