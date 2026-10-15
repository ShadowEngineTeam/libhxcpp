import haxe.io.Bytes;
import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.ssl.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

function listen():Socket {
	final cert = Certificate.fromString(haxe.Resource.getString("cert"));
	final key = Key.readPEM(haxe.Resource.getString("key"), false);
	final listener = new Socket();
	listener.verifyCert = false;
	listener.setCertificate(cert, key);
	listener.bind(new Host("127.0.0.1"), 0);
	listener.listen(1);
	return listener;
}

function connect(port:Int):Socket {
	final client = new Socket();
	client.verifyCert = false;
	client.connect(new Host("127.0.0.1"), port);
	return client;
}

function writeAfterClose() {
	final listener = listen();
	final done = new Lock();
	Thread.create(() -> {
		final peer = listener.accept();
		peer.handshake();
		done.wait();
		peer.close();
	});
	final client = connect(listener.host().port);
	client.close();
	try {
		client.write("hello");
		Sys.println("write after close returned");
	} catch (e:Dynamic) {
		Sys.println("write after close threw");
	}
	done.release();
	listener.close();
}

function corruptRecord() {
	final listener = listen();
	final done = new Lock();
	Thread.create(() -> {
		final peer = listener.accept();
		peer.handshake();
		peer.output.writeString("hello");
		peer.output.flush();
		Sys.sleep(0.2);
		final bad = Bytes.alloc(5 + 64);
		bad.set(0, 0x17);
		bad.set(1, 3);
		bad.set(2, 3);
		bad.set(3, 0);
		bad.set(4, 64);
		for (i in 5...bad.length)
			bad.set(i, i * 7);
		@:privateAccess cpp.NativeSocket.socket_send(peer.__s, bad.getData(), 0, bad.length);
		done.wait();
		peer.close();
	});
	final client = connect(listener.host().port);
	try {
		client.read();
		Sys.println("corrupt record returned");
	} catch (e:Dynamic) {
		Sys.println("corrupt record threw");
	}
	done.release();
	client.close();
	listener.close();
}

function main() {
	writeAfterClose();
	corruptRecord();
}
