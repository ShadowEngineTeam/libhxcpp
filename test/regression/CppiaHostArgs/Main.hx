import haxe.io.Path;
import sys.io.Process;

using StringTools;

// Runs the Cppia host that haxelib run hxcpp uses, built from
// project/cppia/Cppia.hx, the ways it is called. The script prints its
// Sys.args(), which holds only what follows the script.
class Main {
	static var dir = Path.directory(Sys.programPath());
	static var host = Path.join([dir, "host", "Cppia" + (Sys.systemName() == "Windows" ? ".exe" : "")]);
	static var script = Path.join([dir, "script.cppia"]);

	static function run(args:Array<String>):String {
		var p = new Process(host, args);
		var out = p.stdout.readAll().toString().replace("\r\n", "\n").trim();
		var code = p.exitCode();
		p.close();
		if (code != 0)
			Sys.stderr().writeString('${args.join(" ")}: exit code $code\n');
		return out;
	}

	static function check(what:String, args:Array<String>, expected:String) {
		var seen = run(args);
		if (seen != expected)
			Sys.stderr().writeString('$what: got $seen\n');
		Sys.println('$what: ${seen == expected}');
	}

	static function main() {
		check("a script run alone sees no arguments", [script], "[]");
		check("a script sees the arguments after it", [script, "a", "-b"], "[a,-b]");
		check("a -jit before the script is the host's", ["-jit", script, "a", "-b"], "[a,-b]");
		check("a -jit after the script is the script's too", [script, "x", "-jit"], "[x,-jit]");
		var fingerprint = run(["-fingerprint"]);
		Sys.println('-fingerprint prints 16 hex digits: ${~/^[0-9a-f]{16}$/.match(fingerprint)}');
	}
}
