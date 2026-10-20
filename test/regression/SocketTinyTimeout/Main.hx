import sys.net.Host;
import sys.net.Socket;

function expires(timeout:Float):Bool {
	var server = new Socket();
	server.bind(new Host("127.0.0.1"), 0);
	server.listen(1);
	var port = server.host().port;
	var client = new Socket();
	client.connect(new Host("127.0.0.1"), port);
	var peer = server.accept();
	var sent = new sys.thread.Lock();
	sys.thread.Thread.create(() -> {
		Sys.sleep(0.1);
		peer.output.writeByte(1);
		sent.release();
	});
	client.setTimeout(timeout);
	var expired = try {
		client.input.readByte();
		false;
	} catch (e:Dynamic) {
		true;
	}
	sent.wait();
	client.close();
	peer.close();
	server.close();
	return expired;
}

function main() {
	Sys.println("tiny timeout expired: " + expires(0.0000001));
	Sys.println("normal timeout expired: " + expires(0.01));
}
