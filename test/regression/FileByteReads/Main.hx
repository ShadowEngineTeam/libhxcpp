function main() {
	var path = haxe.io.Path.directory(Sys.programPath()) + "/bytes.txt";
	var text = [for (i in 0...3000) 'line $i'].join("\n");
	sys.io.File.saveContent(path, text);
	var f = sys.io.File.read(path);
	var first = String.fromCharCode(f.readByte()) + String.fromCharCode(f.readByte());
	Sys.println(first + " tell " + f.tell());
	var bulk = f.read(8).toString();
	Sys.println(bulk + " tell " + f.tell());
	f.seek(5000, SeekBegin);
	Sys.println("after seek " + f.tell() + " " + (f.readByte() == text.charCodeAt(5000)));
	f.seek(-3, SeekCur);
	Sys.println("seek back " + f.tell() + " " + (f.readByte() == text.charCodeAt(4998)));
	f.seek(0, SeekBegin);
	var lines = 0;
	var last = "";
	try
		while (true) {
			last = f.readLine();
			lines++;
		}
	catch (_:haxe.io.Eof) {}
	Sys.println(lines + " lines, last " + last + ", eof " + f.eof());
	f.seek(-4, SeekEnd);
	Sys.println("end " + f.readAll().toString());
	f.close();
	var sum = 0, n = 0;
	var g = sys.io.File.read(path);
	try
		while (true) {
			sum += g.readByte();
			n++;
		}
	catch (_:haxe.io.Eof) {}
	g.close();
	var expected = 0;
	for (i in 0...text.length)
		expected += text.charCodeAt(i);
	Sys.println(n == text.length && sum == expected);
	var h = sys.io.File.read(path);
	var count = 0;
	var threw = false;
	try
		while (!h.eof()) {
			h.readByte();
			count++;
		}
	catch (_:haxe.io.Eof) {
		threw = true;
	}
	Sys.println("eof loop read " + count + ", threw " + threw + ", eof " + h.eof());
	h.close();
	sys.FileSystem.deleteFile(path);
}
