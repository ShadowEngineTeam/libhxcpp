import haxe.io.Bytes;
import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.ssl.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

// A TLS 1.2 ClientHello whose server_name extension is followed by renegotiation_info
function clientHello():Bytes {
	final hex = "16030100" + "4a" + "01000046" + "0303" + [for (i in 0...32) "01"].join("") + "00" + "0004c02f009c" + "0100" + "0019"
		+ "00000010000e00000b" + Bytes.ofString("example.com").toHex() + "ff01000100";
	return Bytes.ofHex(hex);
}

function main() {
	final cert = Certificate.fromString(haxe.Resource.getString("cert"));
	final key = Key.readPEM(haxe.Resource.getString("key"), false);
	var seen:String = null;
	final called = new Lock();
	final listener = new Socket();
	listener.verifyCert = false;
	listener.setCertificate(cert, key);
	listener.addSNICertificate(name -> {
		seen = name;
		called.release();
		true;
	}, cert, key);
	listener.bind(new Host("127.0.0.1"), 0);
	listener.listen(1);
	final port = listener.host().port;
	final done = new Lock();
	Thread.create(() -> {
		final client = new sys.net.Socket();
		client.connect(new Host("127.0.0.1"), port);
		client.output.write(clientHello());
		called.wait(10);
		client.close();
		done.release();
	});
	final socket = listener.accept();
	try {
		socket.handshake();
	} catch (e:Dynamic) {}
	done.wait();
	Sys.println(seen == null ? "no server name" : 'server name ${haxe.Json.stringify(seen)} (${seen.length})');
}
