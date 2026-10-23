import sys.io.Process;
import sys.io.File;
import sys.FileSystem;

using StringTools;

function runOutput(test:String):String {
	final slash = Sys.systemName() == "Windows" ? "\\" : "/";
	final proc = new Process([test, "bin", 'Main'].join(slash));
	final code = proc.exitCode();

	if (code != 0) {
		throw 'return code was $code';
	}

	return proc.stdout.readAll().toString().replace("\r\n", "\n");
}

function main() {
	var successes = 0;
	var total = 0;

	final args = Sys.args();
	// Comma-separated tests that the Haxe in use cannot build, such as one its
	// compiler rejects
	final skipList = Sys.getEnv("REGRESSION_SKIP");
	final skip = skipList == null ? [] : skipList.split(",");

	for (test in FileSystem.readDirectory(".")) {
		if (!FileSystem.isDirectory(test)) {
			continue;
		}
		if (skip.contains(test)) {
			Sys.println('Skipping $test');
			continue;
		}

		total++;

		// From inside the test, not with -C: Haxe 5.0.0-preview.1 does not keep the
		// -C directory for the sections after --next, which the cppia tests use
		final root = Sys.getCwd();
		Sys.setCwd(test);
		final buildExitCode = Sys.command("haxe", ["build.hxml"].concat(args));
		Sys.setCwd(root);
		if (buildExitCode != 0) {
			Sys.println('Failed to build test $test. Exit code: $buildExitCode');
			continue;
		}

		final expectedStdout = File.getContent('$test/stdout.txt').replace("\r\n", "\n");
		final actualStdout = try {
			runOutput(test);
		} catch (e) {
			Sys.println('Test $test failed: $e');
			continue;
		};

		if (actualStdout != expectedStdout) {
			Sys.println('Test $test failed: Output did not match');

			Sys.println("Expected stdout:");
			Sys.println(expectedStdout);
			Sys.println("Actual stdout:");
			Sys.println(actualStdout);
			continue;
		}

		successes++;
	}

	Sys.println('Regression tests complete. Successes: $successes / $total');

	if (successes < total) {
		Sys.exit(1);
	}
}
