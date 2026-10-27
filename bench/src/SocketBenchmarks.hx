package;

import haxe.io.Bytes;
import haxe.io.BufferInput;
import sys.net.Host;
import sys.net.Socket;
import sys.net.UdpSocket;
import sys.thread.Deque;
import sys.thread.Thread;

/**
	Line-oriented reads from a loopback TCP stream. A writer thread sends
	128 KiB of 128-byte CRLF lines for every run(), which reads them back
	with readLine, straight from the socket's input or through a BufferInput.
**/
class SocketReadLine extends Benchmark {
	static inline var LINE = 128;
	static inline var LINES = 1024;

	final buffered:Bool;
	var payload:Bytes;
	var reader:Socket;
	var input:haxe.io.Input;
	final requests = new Deque<Bool>();

	public function new(buffered:Bool) {
		super(buffered ? "socket_readline_buffered" : "socket_readline", "lines", LINES);
		this.buffered = buffered;
	}

	override public function setup() {
		payload = Bytes.alloc(LINE * LINES);
		for (l in 0...LINES) {
			for (c in 0...LINE - 2)
				payload.set(l * LINE + c, 97 + (l + c) % 26);
			payload.set(l * LINE + LINE - 2, 13);
			payload.set(l * LINE + LINE - 1, 10);
		}
		var server = new Socket();
		server.bind(new Host("127.0.0.1"), 0);
		server.listen(1);
		var port = server.host().port;
		var requests = this.requests;
		var payload = this.payload;
		Thread.create(() -> {
			var writer = new Socket();
			writer.connect(new Host("127.0.0.1"), port);
			while (requests.pop(true))
				writer.output.write(payload);
			writer.close();
		});
		reader = server.accept();
		server.close();
		input = buffered ? new BufferInput(reader.input, Bytes.alloc(16384)) : reader.input;
	}

	override public function run():Int {
		requests.add(true);
		var sum = 0;
		for (l in 0...LINES) {
			var line = input.readLine();
			if (line.length != LINE - 2)
				throw 'socket_readline: line $l is ${line.length} long';
			sum = (sum * 31 + StringTools.fastCodeAt(line, l % (LINE - 2))) | 0;
		}
		return sum;
	}
}

/**
	Poll.events(0) over a set of UDP sockets bound to loopback. Idle, none of
	them is ready, and the cost of waiting grows with the sockets registered
	rather than the ones ready. Ready, every socket holds a datagram, which
	is never read, so every call reports them all. With prepare, every call
	registers the set again first, as Poll.poll does.

	The default sizes stay under the 256 descriptors a macOS process gets
	by default. BENCH_POLL_SOCKETS, a comma-separated list of sizes, adds
	idle benchmarks of those sizes, for measuring the larger sets by hand.
**/
class PollIdle extends Benchmark {
	static inline var CALLS = 200;

	public static function all():Array<Benchmark> {
		var list:Array<Benchmark> = [
			new PollIdle(64), new PollIdle(192), new PollIdle(192, Ready), new PollIdle(192, Prepare),
		];
		var extra = Sys.getEnv("BENCH_POLL_SOCKETS");
		if (extra != null && extra != "")
			for (size in extra.split(","))
				list.push(new PollIdle(Std.parseInt(size)));
		return list;
	}

	final count:Int;
	final mode:PollMode;
	var poll:cpp.net.Poll;
	var sockets:Array<UdpSocket> = [];

	public function new(count:Int, mode = Idle) {
		super(switch (mode) {
			case Idle: 'poll_idle_$count';
			case Ready: 'poll_ready_$count';
			case Prepare: 'poll_prepare_$count';
		}, "calls", CALLS);
		this.count = count;
		this.mode = mode;
	}

	override public function setup() {
		for (i in 0...count) {
			var s = new UdpSocket();
			s.bind(new Host("127.0.0.1"), 0);
			sockets.push(s);
		}
		if (mode == Ready) {
			var sender = new UdpSocket();
			var one = Bytes.alloc(1);
			for (s in sockets) {
				var to = new sys.net.Address();
				to.host = s.host().host.ip;
				to.port = s.host().port;
				sender.sendTo(one, 0, 1, to);
			}
			sender.close();
		}
		poll = new cpp.net.Poll(count);
		poll.prepare(cast sockets, []);
		if (mode == Ready) {
			// Loopback delivers at once, but wait until every datagram is there
			for (attempt in 0...100) {
				if (ready() == count)
					break;
				Sys.sleep(0.01);
			}
			if (ready() != count)
				throw 'poll_ready: ${ready()} of $count sockets ready';
		}
	}

	function ready():Int {
		poll.events(0);
		var n = 0;
		while (poll.readIndexes[n] >= 0)
			n++;
		return n;
	}

	override public function run():Int {
		var expected = mode == Ready ? count : 0;
		var total = 0;
		for (i in 0...CALLS) {
			if (mode == Prepare)
				poll.prepare(cast sockets, []);
			var n = ready();
			if (n != expected)
				throw '$name: $n sockets ready';
			total += n;
		}
		return total + count;
	}
}

enum PollMode {
	Idle;
	Ready;
	Prepare;
}
