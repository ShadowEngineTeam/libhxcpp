import cpp.NativeSocket;

// Unconnected sockets have no exceptional condition, whatever their
// descriptor. Emscripten's select reads and writes only the first 64
// descriptors of a set, so one above that kept the bit it was given and
// came back as ready (libhxcpp #345)
class Main {
	static inline var COUNT = 80;

	static function main() {
		NativeSocket.socket_init();
		var sockets:Array<Dynamic> = [for (i in 0...COUNT) NativeSocket.socket_new(false)];

		for (i in [0, 60, 61, 62, 79]) {
			var result = NativeSocket.socket_select([], [], [sockets[i]], 0);
			var exceptional:Array<Dynamic> = result[2];
			Sys.println('socket $i not exceptional: ${exceptional.length == 0}');
		}

		// Windows takes at most 64 sockets in a set
		var last64 = sockets.slice(COUNT - 64);
		var result = NativeSocket.socket_select([], [], last64, 0);
		var exceptional:Array<Dynamic> = result[2];
		Sys.println('none of the last 64 exceptional: ${exceptional.length == 0}');

		var inPlace:Array<Dynamic> = [sockets[COUNT - 1]];
		NativeSocket.socket_fast_select([], [], inPlace, 0);
		Sys.println('in-place select removes the last: ${inPlace.length == 0}');

		inPlace = sockets.slice(COUNT - 64);
		NativeSocket.socket_fast_select([], [], inPlace, 0);
		Sys.println('in-place select removes the last 64: ${inPlace.length == 0}');

		for (socket in sockets)
			NativeSocket.socket_close(socket);
	}
}
