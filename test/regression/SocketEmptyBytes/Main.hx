import sys.net.Host;
import sys.net.Socket;

function main() {
	var server = new Socket();
	server.bind(new Host("127.0.0.1"), 0);
	server.listen(1);
	var client = new Socket();
	client.connect(new Host("127.0.0.1"), server.host().port);
	var accepted = server.accept();
	var empty = haxe.io.Bytes.alloc(0);
	client.output.writeBytes(empty, 0, 0);
	client.output.writeFullBytes(empty, 0, 0);
	Sys.println("data length " + empty.getData().length);
	client.output.writeString("hello");
	client.output.flush();
	var got = haxe.io.Bytes.alloc(5);
	accepted.input.readFullBytes(got, 0, 5);
	Sys.println("received " + got.toString());
	accepted.close();
	client.close();
	server.close();
}
