import cpp.NativeSocket;

// A socket starts with no timeout, which is what a zero timeout asks for.
// Emscripten has no socket timeout options, so setting one failed, and so
// did constructing a sys.net.Socket, which sets its zero timeout
// (libhxcpp #344)
class Main {
	static function check(claim:String, f:() -> Bool) {
		var result = try f() catch (e:Dynamic) {
			Sys.stderr().writeString('$claim threw $e\n');
			false;
		}
		Sys.println('$claim: $result');
	}

	static function main() {
		NativeSocket.socket_init();
		var handle:Dynamic = null;
		check("native socket allocated", () -> {
			handle = NativeSocket.socket_new(false);
			handle != null;
		});
		check("zero timeout set", () -> {
			NativeSocket.socket_set_timeout(handle, 0.0);
			true;
		});
		check("null timeout set", () -> {
			NativeSocket.socket_set_timeout(handle, null);
			true;
		});
		// Where a positive timeout cannot be honoured it throws, so this one
		// only reports what happened
		try {
			NativeSocket.socket_set_timeout(handle, 1.5);
			Sys.stderr().writeString("positive timeout set\n");
		} catch (e:Dynamic) {
			Sys.stderr().writeString('positive timeout threw $e\n');
		}
		if (handle != null)
			NativeSocket.socket_close(handle);
		check("sys.net.Socket constructed", () -> {
			var socket = new sys.net.Socket();
			socket.close();
			true;
		});
	}
}
