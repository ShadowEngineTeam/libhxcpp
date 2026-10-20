function main() {
	var windows = Sys.systemName() == "Windows";
	var p = windows ? cpp.NativeProcess.process_run("cmd", ["/c", "exit 0"]) : cpp.NativeProcess.process_run("sh", ["-c", "exit 0"]);
	cpp.NativeProcess.process_exit(p, true);
	var ops = [cpp.NativeProcess.process_stdout_read, cpp.NativeProcess.process_stderr_read, cpp.NativeProcess.process_stdin_write];
	for (op in ops) {
		var buf = new haxe.io.BytesData();
		var got = op(p, buf, 0, 0);
		Sys.println('returned $got, buffer length ${buf.length}');
	}
	cpp.NativeProcess.process_close(p);
}
