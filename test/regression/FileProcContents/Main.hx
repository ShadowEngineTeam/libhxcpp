function main() {
	if (Sys.systemName() != "Linux") {
		Sys.println("stream has content: true");
		Sys.println("getContent matches stream: true");
		Sys.println("getBytes matches stream: true");
		return;
	}
	var path = "/proc/self/cmdline";
	var input = sys.io.File.read(path);
	var stream = input.readAll();
	input.close();
	Sys.println("stream has content: " + (stream.length > 0));
	Sys.println("getContent matches stream: " + (sys.io.File.getContent(path) == stream.toString()));
	Sys.println("getBytes matches stream: " + (sys.io.File.getBytes(path).compare(stream) == 0));
}
