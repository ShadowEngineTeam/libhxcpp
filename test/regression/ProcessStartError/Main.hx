function main() {
	if (Sys.systemName() != "Windows") {
		Sys.println("explained");
		return;
	}
	try {
		cpp.NativeProcess.process_run("no-such-program-for-libhxcpp", []);
		Sys.println("started");
	} catch (e:Dynamic) {
		var message = Std.string(e);
		Sys.println(message.indexOf("(2)") >= 0 ? "explained" : "unexplained: " + message);
	}
}
