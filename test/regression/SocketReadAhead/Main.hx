import cpp.NativeSocket;
import cpp.NativeSsl;
import cpp.net.Poll;
import cpp.vm.Gc;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.thread.Deque;
import sys.thread.Lock;
import sys.thread.Thread;

// A byte read from a stream socket takes what else the kernel already has.
// Every other read, select, both polls and TLS must see the stream as they
// did when each byte was a recv of its own. Where the kernel's behaviour
// differs between systems, a socket that read ahead is compared with one
// that did not: its first byte is taken with readBytes, which never reads
// ahead.
class Main {
	static function pair():{a:Socket, b:Socket} {
		var listener = new Socket();
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(1);
		var b = new Socket();
		b.connect(new Host("127.0.0.1"), listener.host().port);
		var a = listener.accept();
		listener.close();
		return {a: a, b: b};
	}

	// Waits until what was sent to s is in its kernel buffer
	static function settle(s:Socket) {
		Socket.select([s], null, null, 5);
		Sys.sleep(0.05);
	}

	static function send(s:Socket, text:String) {
		s.output.writeString(text);
	}

	// Ready to read, by select, fast select, Poll.events and Poll.poll
	static function readable(s:Socket):String {
		var select = Socket.select([s], null, null, 0).read.length == 1;
		var fast:Array<Dynamic> = [s];
		NativeSocket.socket_fast_select(fast, [], [], 0.0);
		var poll = new Poll(2);
		poll.prepare([s], []);
		poll.events(0);
		var events = poll.readIndexes[0] == 0;
		var polled = poll.poll([s], 0).length == 1;
		return '$select ${fast.length == 1} $events $polled';
	}

	static function outcome(f:() -> String):String {
		return try f() catch (e:haxe.io.Eof) "Eof" catch (e:haxe.io.Error) 'Error($e)' catch (e:Dynamic) 'thrown($e)';
	}

	static function firstByte(s:Socket, ahead:Bool) {
		if (ahead)
			s.input.readByte();
		else
			s.input.readBytes(Bytes.alloc(1), 0, 1);
	}

	static function readAll(s:Socket):String {
		var got = new StringBuf();
		var buf = Bytes.alloc(16);
		for (i in 0...4) {
			var n = try s.input.readBytes(buf, 0, buf.length) catch (e:haxe.io.Eof) {
				got.add("|Eof");
				break;
			} catch (e:Dynamic) {
				got.add('|thrown($e)');
				break;
			}
			got.add(buf.getString(0, n));
		}
		return got.toString();
	}

	// What a scenario shows, after the first byte is read with or without
	// reading ahead
	static function compare(name:String, scenario:(s:Socket) -> String) {
		var seen = [];
		for (ahead in [true, false]) {
			var p = pair();
			send(p.b, "12345");
			settle(p.a);
			firstByte(p.a, ahead);
			seen.push(scenario(p.a));
			p.a.close();
			p.b.close();
		}
		Sys.println('$name sees what it would have without reading ahead: ${seen[0] == seen[1]}');
		if (seen[0] != seen[1])
			Sys.stderr().writeString('  read ahead: ${seen[0]}\n  byte at a time: ${seen[1]}\n');
	}

	static function mixedReads() {
		var p = pair();
		send(p.b, "abcdefghij\r\nline two\r\nrest of it");
		p.b.close();
		settle(p.a);
		var input = p.a.input;
		var first = String.fromCharCode(input.readByte());
		Gc.run(true);
		var buf = Bytes.alloc(3);
		var n = input.readBytes(buf, 0, 3);
		var line = input.readLine();
		Gc.run(true);
		var two = input.readLine();
		var rest = p.a.read();
		var got = '$first|${buf.getString(0, n)}|$line|$two|$rest';
		Sys.println('readByte, readBytes, readLine and read keep the stream in order: ${got == "a|bcd|efghij|line two|rest of it"}');
		p.a.close();
	}

	static function readiness() {
		var p = pair();
		send(p.b, "xyz");
		settle(p.a);
		p.a.input.readByte();
		Sys.println('a socket holding bytes is readable by select, fast select, events and poll: ${readable(p.a) == "true true true true"}');
		var start = haxe.Timer.stamp();
		Socket.select([p.a], null, null, 5);
		var poll = new Poll(1);
		poll.prepare([p.a], []);
		poll.events(5);
		Sys.println('held bytes end a wait at once: ${haxe.Timer.stamp() - start < 2}');
		p.a.input.readByte();
		p.a.input.readByte();
		Sys.println('once they are read it is not: ${readable(p.a) == "false false false false"}');
		p.a.close();
		p.b.close();
	}

	static function endOfStream() {
		var p = pair();
		send(p.b, "ok");
		p.b.close();
		settle(p.a);
		var input = p.a.input;
		var got = String.fromCharCode(input.readByte()) + String.fromCharCode(input.readByte());
		Sys.println('the end of the stream comes after the held bytes: ${got == "ok" && outcome(() -> Std.string(input.readByte())) == "Eof"}');
		p.a.close();
	}

	static function nonBlocking() {
		var p = pair();
		send(p.b, "nb");
		settle(p.a);
		p.a.setBlocking(false);
		var input = p.a.input;
		var got = String.fromCharCode(input.readByte()) + String.fromCharCode(input.readByte());
		Sys.println('a nonblocking read blocks after the held bytes: ${got == "nb" && outcome(() -> Std.string(input.readByte())) == "Error(Blocked)"}');
		p.a.close();
		p.b.close();
	}

	static function timeout() {
		var p = pair();
		send(p.b, "tt");
		settle(p.a);
		p.a.setTimeout(0.2);
		var input = p.a.input;
		input.readByte();
		var start = haxe.Timer.stamp();
		input.readByte();
		var held = haxe.Timer.stamp() - start;
		start = haxe.Timer.stamp();
		var result = outcome(() -> Std.string(input.readByte()));
		var waited = haxe.Timer.stamp() - start;
		Sys.println('a held byte comes at once: ${held < 0.1}');
		Sys.println('a read past the held bytes waits out the timeout: ${result != "116" && waited >= 0.1 && waited < 3}');
		p.a.close();
		p.b.close();
	}

	// Each of two threads reads its share of every round a byte at a time.
	// The bytes are 0 to 254 in order, so each thread's must ascend.
	static function twoReaders() {
		var p = pair();
		var go = [new Deque<Bool>(), new Deque<Bool>()];
		var done = new Deque<Array<Int>>();
		var shares = [127, 128];
		for (t in 0...2)
			Thread.create(() -> {
				while (go[t].pop(true)) {
					var got = [];
					for (i in 0...shares[t])
						got.push(p.a.input.readByte());
					done.add(got);
				}
			});
		var ordered = true;
		var complete = true;
		var payload = Bytes.alloc(255);
		for (i in 0...255)
			payload.set(i, i);
		for (round in 0...100) {
			go[0].add(true);
			go[1].add(true);
			p.b.output.writeFullBytes(payload, 0, 255);
			var seen = [for (i in 0...255) false];
			for (t in 0...2) {
				var got = done.pop(true);
				for (i in 0...got.length) {
					if (i > 0 && got[i] <= got[i - 1])
						ordered = false;
					seen[got[i]] = true;
				}
			}
			if (seen.indexOf(false) >= 0)
				complete = false;
			if (round % 25 == 0)
				Gc.run(true);
		}
		go[0].add(false);
		go[1].add(false);
		Sys.println('two threads reading a byte at a time each get their bytes in order: $ordered');
		Sys.println('and between them every byte once: $complete');
		p.a.close();
		p.b.close();
	}

	// select and poll do not wait for a read blocked in recv
	static function blockedReader() {
		var p = pair();
		var got = new Deque<Int>();
		Thread.create(() -> got.add(p.a.input.readByte()));
		Sys.sleep(0.1);
		Sys.println('select and poll beside a blocked read return: ${readable(p.a) == "false false false false"}');
		send(p.b, "q");
		Sys.println('the blocked read gets the byte sent: ${got.pop(true) == "q".code}');
		p.a.close();
		p.b.close();
	}

	static function closed() {
		compare("a native read after close", s -> {
			var handle = @:privateAccess s.__s;
			NativeSocket.socket_close(handle);
			outcome(() -> Std.string(NativeSocket.socket_recv_char(handle))) + " "
				+ outcome(() -> Std.string(NativeSocket.socket_recv(handle, Bytes.alloc(4).getData(), 0, 4)));
		});
	}

	// A line in the clear, then TLS on the same connection, its ClientHello
	// sent with the line: the server reads the line a byte at a time, so the
	// hello is read ahead with it, and TLS must still get it
	static function startTls() {
		var cert = Certificate.fromString(haxe.Resource.getString("cert"));
		var key = Key.readPEM(haxe.Resource.getString("key"), false);
		var p = pair();
		var hello = Bytes.ofString("STARTTLS\r\n");
		var both = Bytes.alloc(hello.length + clientHello().length);
		both.blit(0, hello, 0, hello.length);
		both.blit(hello.length, clientHello(), 0, clientHello().length);
		p.b.output.writeFullBytes(both, 0, both.length);
		settle(p.a);
		Sys.println('the line in the clear is read: ${p.a.input.readLine() == "STARTTLS"}');

		var server = new sys.ssl.Socket();
		server.verifyCert = false;
		server.setCertificate(cert, key);
		var seen:String = null;
		server.addSNICertificate(name -> {
			seen = name;
			true;
		}, cert, key);
		var conf = @:privateAccess server.buildSSLConfig(true);
		var ssl = NativeSsl.ssl_new(conf);
		p.a.setTimeout(5);
		NativeSsl.ssl_set_socket(ssl, @:privateAccess p.a.__s);
		Sys.println('the hello read ahead keeps the socket readable: ${readable(p.a) == "true true true true"}');
		var upgraded = Type.createEmptyInstance(sys.ssl.Socket);
		@:privateAccess {
			upgraded.__s = p.a.__s;
			upgraded.ssl = ssl;
			upgraded.handshakeDone = false;
		}
		// The client sends nothing more, so the handshake fails after the hello
		Thread.create(() -> {
			Sys.sleep(0.5);
			p.b.close();
		});
		try upgraded.handshake() catch (e:Dynamic) {}
		Sys.println('TLS gets the hello read ahead: ${seen == "example.com"}');
		p.a.close();
	}

	// TLS sockets read through TLS, which never reads ahead
	static function tlsLines() {
		var cert = Certificate.fromString(haxe.Resource.getString("cert"));
		var key = Key.readPEM(haxe.Resource.getString("key"), false);
		var listener = new sys.ssl.Socket();
		listener.verifyCert = false;
		listener.setCertificate(cert, key);
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(1);
		var port = listener.host().port;
		var done = new Lock();
		Thread.create(() -> {
			var client = new sys.ssl.Socket();
			client.verifyCert = false;
			client.connect(new Host("127.0.0.1"), port);
			client.output.writeString("first line\nsecond line\n");
			Sys.println('TLS sockets read lines both ways: ${client.input.readLine() == "first line, second line"}');
			client.close();
			done.release();
		});
		var conn = listener.accept();
		var one = conn.input.readLine();
		var two = conn.input.readLine();
		conn.output.writeString('$one, $two\n');
		done.wait();
		conn.close();
		listener.close();
	}

	// A TLS 1.2 ClientHello whose server_name extension names example.com
	static function clientHello():Bytes {
		var hex = "16030100" + "4a" + "01000046" + "0303" + [for (i in 0...32) "01"].join("") + "00" + "0004c02f009c" + "0100" + "0019"
			+ "00000010000e00000b" + Bytes.ofString("example.com").toHex() + "ff01000100";
		return Bytes.ofHex(hex);
	}

	static function main() {
		mixedReads();
		readiness();
		endOfStream();
		nonBlocking();
		timeout();
		compare("a read shutdown", s -> {
			s.shutdown(true, false);
			readAll(s);
		});
		compare("readiness after a read shutdown", s -> {
			s.shutdown(true, false);
			readable(s);
		});
		compare("an empty read", s -> outcome(() -> Std.string(s.input.readBytes(Bytes.alloc(1), 0, 0))));
		closed();
		twoReaders();
		blockedReader();
		startTls();
		tlsLines();
	}
}
