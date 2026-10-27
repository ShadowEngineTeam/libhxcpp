import cpp.cppia.Host;
import cpp.cppia.Module;
import haxe.io.Bytes;

// A module with a __cppia_host resource loads only into the host whose
// fingerprint it holds. required.cppia is built with a placeholder, which
// stands for another host's fingerprint until it is replaced with this one's.
class Main {
	static function load(bytes:Bytes):String {
		try {
			var module = Module.fromData(bytes.getData());
			module.boot();
			module.run();
			return "loaded";
		} catch (e:Dynamic) {
			return "refused: " + e;
		}
	}

	static function find(bytes:Bytes, text:String):Int {
		var pattern = Bytes.ofString(text);
		for (i in 0...bytes.length - pattern.length + 1)
			if (bytes.sub(i, pattern.length).compare(pattern) == 0)
				return i;
		return -1;
	}

	static function check(what:String, seen:String, expected:String) {
		if (seen != expected)
			Sys.stderr().writeString('$what: got $seen\n');
		Sys.println('$what: ${seen == expected}');
	}

	static function main() {
		var fingerprint:String = untyped __global__.__scriptable_host_fingerprint();
		Sys.println('the fingerprint is 16 hex digits: ${~/^[0-9a-f]{16}$/.match(fingerprint)}');
		Sys.println('the fingerprint is the same each time: ${fingerprint == untyped __global__.__scriptable_host_fingerprint()}');

		var dir = haxe.io.Path.directory(Sys.programPath());
		var plain = sys.io.File.getBytes('$dir/plain.cppia');
		var required = sys.io.File.getBytes('$dir/required.cppia');
		var placeholder = "XXXXXXXXXXXXXXXX";
		var matching = required.sub(0, required.length);
		matching.blit(find(matching, placeholder), Bytes.ofString(fingerprint), 0, placeholder.length);

		for (jit in [false, true]) {
			Host.enableJit(jit);
			check('jit $jit: a module without the resource loads', load(plain), "loaded");
			check('jit $jit: a module for another host is refused, naming both', load(required),
				'refused: This cppia module was built for host $placeholder, but this host is $fingerprint');
			check('jit $jit: a module for this host loads', load(matching), "loaded");
		}
	}
}
