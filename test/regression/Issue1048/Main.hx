function main() {
	var bad = "missing" + String.fromCharCode(0xD800) + ".txt";
	try {
		sys.io.File.getContent(bad);
		Sys.println("getContent: no error");
	} catch (e:Dynamic) {
		Sys.println("getContent: caught");
	}
	try {
		sys.io.File.getBytes(bad);
		Sys.println("getBytes: no error");
	} catch (e:Dynamic) {
		Sys.println("getBytes: caught");
	}
	try {
		sys.io.File.read(bad).close();
		Sys.println("read: no error");
	} catch (e:Dynamic) {
		Sys.println("read: caught");
	}
}
