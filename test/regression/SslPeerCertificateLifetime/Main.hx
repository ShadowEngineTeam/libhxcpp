import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.ssl.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

class Main {
	static function main() {
		var listener=new Socket();
		listener.verifyCert=false;
		listener.setCertificate(Certificate.fromString(haxe.Resource.getString("cert")),Key.readPEM(haxe.Resource.getString("key"),false));
		listener.bind(new Host("127.0.0.1"),0);
		listener.listen(1);
		var release=new Lock(),done=new Lock();
		Thread.create(() -> {
			var accepted=listener.accept();
			accepted.setTimeout(10);
			accepted.handshake();
			release.wait(10);
			accepted.close();
			done.release();
		});
		var client=new Socket();
		client.verifyCert=false;
		client.setTimeout(10);
		client.connect(new Host("127.0.0.1"),listener.host().port);
		var certificate=client.peerCertificate();
		var before=certificate.commonName;
		Sys.println("peer certificate available: "+(before!=null));
		client.close();
		Sys.println("peer certificate survives socket close: "+(certificate.commonName==before));
		release.release();
		if(!done.wait(10)) throw "Server did not finish";
		listener.close();
	}
}