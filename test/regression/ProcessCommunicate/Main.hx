import haxe.io.Bytes;

// _hx_std_process_communicate writes stdin while it drains stdout and stderr,
// so a child cannot block on a full pipe, and stops at a deadline or once the
// child has exited even when a descendant keeps a pipe open.
class Main {
	static function child(mode:String) {
		var out = Sys.stdout();
		switch (mode) {
			case "stderr-first":
				// More than a pipe holds, before anything on stdout
				Sys.stderr().write(Bytes.alloc(1 << 20));
				Sys.stderr().flush();
				out.writeString("done");
			case "echo":
				var buf = Bytes.alloc(65536);
				try {
					while (true) {
						var n = Sys.stdin().readBytes(buf, 0, buf.length);
						out.writeBytes(buf, 0, n);
					}
				} catch (e:haxe.io.Eof) {}
			case "sleep":
				Sys.sleep(30);
			case "hold":
				Sys.sleep(3);
			case "flood":
				for (i in 0...64)
					out.write(Bytes.alloc(65536));
			case "descendant":
				// A child of its own inherits stdout and keeps it open after this exits
				if (Sys.systemName() == "Windows")
					Sys.command('start "" /b "' + Sys.programPath() + '" hold');
				else
					Sys.command('"' + Sys.programPath() + '" hold &');
				out.writeString("parent");
		}
		out.flush();
		Sys.exit(3);
	}

	static function communicate(mode:String, input:Bytes, timeout:Float, maxOutput:Int):Dynamic {
		var process = new sys.io.Process(Sys.programPath(), [mode]);
		var handle = @:privateAccess process.p;
		return untyped __global__._hx_std_process_communicate(handle, input == null ? null : input.getData(), timeout, maxOutput);
	}

	static function main() {
		var args = Sys.args();
		if (args.length > 0) {
			child(args[0]);
			return;
		}
		sys.thread.Thread.create(() -> {
			Sys.sleep(60);
			Sys.println("watchdog: communicate hung");
			Sys.exit(1);
		});

		var r = communicate("stderr-first", null, 30, 0);
		Sys.println("1 MB of stderr before stdout: " + (r.stderr.length == 1 << 20) + ", stdout " + Bytes.ofData(r.stdout).toString() + ", exit " + r.exitCode);

		var input = Bytes.alloc(4 << 20);
		for (i in 0...input.length)
			input.set(i, 97 + i % 26);
		r = communicate("echo", input, 30, 0);
		Sys.println("4 MB through stdin and back: " + (Bytes.ofData(r.stdout).compare(input) == 0) + ", exit " + r.exitCode);

		var start = Sys.time();
		r = communicate("sleep", null, 0.5, 0);
		Sys.println("past the deadline: timedOut " + r.timedOut + ", stopped within 5 s " + (Sys.time() - start < 5));

		r = communicate("flood", null, 30, 1000);
		Sys.println("bounded output: kept " + r.stdout.length + ", truncated " + r.stdoutTruncated + ", exit " + r.exitCode);

		start = Sys.time();
		r = communicate("descendant", null, 30, 0);
		Sys.println("descendant holding stdout: stdout " + Bytes.ofData(r.stdout).toString() + ", returned within 2 s " + (Sys.time() - start < 2)
			+ ", timedOut " + r.timedOut);
		Sys.exit(0);
	}
}
