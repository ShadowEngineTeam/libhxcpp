import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.ssl.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

// The listener, its certificate and its SNI callback are dropped before the
// accepted socket handshakes, which still needs all three.
function serve(connect:Int->Void):Socket {
	final cert = Certificate.fromString(haxe.Resource.getString("cert"));
	final key = Key.readPEM(haxe.Resource.getString("key"), false);
	final listener = new Socket();
	listener.verifyCert = false;
	listener.setCertificate(cert, key);
	listener.addSNICertificate(name -> name == "a.test", cert, key);
	listener.bind(new Host("127.0.0.1"), 0);
	listener.listen(1);
	connect(listener.host().port);
	final accepted = listener.accept();
	listener.close();
	return accepted;
}

function main() {
	final read = new Lock();
	final done = new Lock();
	final socket = serve(port -> Thread.create(() -> {
		final client = new Socket();
		client.verifyCert = false;
		client.setHostname("a.test");
		client.connect(new Host("127.0.0.1"), port);
		client.write("x");
		read.wait();
		client.close();
		done.release();
	}));

	for (_ in 0...3)
		cpp.vm.Gc.run(true);
	var churn = [for (i in 0...200000) [i]];
	churn = null;

	socket.handshake();
	final message = socket.input.readString(1);
	read.release();
	Sys.println(message == "x" ? "handshake ok" : "handshake failed");
	done.wait();
}
