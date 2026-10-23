import sys.io.Process;
import sys.thread.Lock;
import sys.thread.Thread;

// On Windows, Process.close waited for a ReadFile another thread had pending on
// the child's stdout, and so for any descendant that inherited the pipe, here a
// cmd.exe that holds it for about 20 s after the shell that started it exits
// (libhxcpp #261). On other systems closing a pipe never waited for a reader.
class Main {
	static function main() {
		if (Sys.systemName() != "Windows") {
			Sys.println("close returned at once: true, reader ended: true");
			return;
		}
		var p = new Process('powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList \'/c ping -n 20 127.0.0.44 >nul\' -NoNewWindow" 2>&1');
		var done = new Lock();
		Thread.create(() -> {
			try p.stdout.readAll() catch (_:Dynamic) {};
			done.release();
		});
		Sys.sleep(3);
		var started = Sys.time();
		p.close();
		var took = Sys.time() - started;
		Sys.println("close returned at once: " + (took < 5) + ", reader ended: " + done.wait(5));
	}
}
