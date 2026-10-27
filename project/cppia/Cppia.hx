import cpp.cppia.Host;

/**
	The Cppia host that `haxelib run hxcpp script.cppia` runs.

	  Cppia [-jit] script.cppia [script arguments...]
	  Cppia -fingerprint

	Options before the script are the host's. The script's Sys.args() holds
	only the arguments after it, as a compiled program's does, so the host's
	options and the script's name are not among them. A `-jit` after the
	script still turns the JIT on, as it did when it was looked for anywhere
	on the command line, and the script sees it too.

	`-fingerprint` prints the host's fingerprint, for a tool to embed in the
	scripts it builds for this host as the `__cppia_host` resource
	(docs/CppiaHostFingerprint.md).
**/
@:cppFileCode('extern int _hxcpp_argc;\nextern char **_hxcpp_argv;')
class Cppia {
	static function main() {
		var args = Sys.args();
		if (args.length == 1 && args[0] == "-fingerprint") {
			Sys.println(untyped __global__.__scriptable_host_fingerprint());
			return;
		}
		var script = 0;
		while (script < args.length && args[script] == "-jit")
			script++;
		if (script == args.length) {
			Sys.println("Usage : Cppia [-jit] scriptname [args...] | Cppia -fingerprint");
			return;
		}
		if (args.indexOf("-jit") >= 0)
			Host.enableJit(true);

		// Sys.args() is argv after argv[0]. Starting argv at the script makes it
		// the arguments after the script.
		var skip = script + 1;
		untyped __cpp__("if (_hxcpp_argc > {0}) { _hxcpp_argv += {0}; _hxcpp_argc -= {0}; }", skip);
		Host.runFile(args[script]);
	}
}
