import sys.io.Process;

function main() {
	final p = Sys.systemName() == "Windows" ? new Process("cmd /c exit 3") : new Process("sh", ["-c", "exit 3"]);
	final first = p.exitCode();
	final second = p.exitCode();
	final polled = p.exitCode(false);
	p.kill();
	p.close();
	Sys.println('$first $second $polled');
}
