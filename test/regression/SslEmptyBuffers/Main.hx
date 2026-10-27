import haxe.io.Bytes;
import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Digest;
import sys.ssl.DigestAlgorithm;
import sys.ssl.Key;
import sys.ssl.Socket;
import sys.thread.Lock;
import sys.thread.Thread;

// The digests of the empty message
final emptyDigests:Array<{alg:DigestAlgorithm, hex:String}> = [
	{alg: MD5, hex: "d41d8cd98f00b204e9800998ecf8427e"},
	{alg: SHA1, hex: "da39a3ee5e6b4b0d3255bfef95601890afd80709"},
	{alg: SHA224, hex: "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f"},
	{alg: SHA256, hex: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
	{alg: SHA384, hex: "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"},
	{
		alg: SHA512,
		hex: "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
	},
	{alg: RIPEMD160, hex: "9c1185a5c5e9fc54612808977ee8f548b2258d31"},
];

// Bytes.length is fixed when the Bytes is made; the data under it is what an
//  empty native call grew
function stillEmpty(b:Bytes)
	return b.length == 0 && b.getData().length == 0;

function claim(name:String, value:Bool)
	Sys.println(name + ": " + value);

function throws(f:() -> Void):Bool {
	try {
		f();
	} catch (e:Dynamic) {
		return true;
	}
	return false;
}

function digests() {
	var matched = true;
	var input = Bytes.alloc(0);
	// Twice on the same input: a grown input changes the second result
	for (round in 0...2)
		for (d in emptyDigests) {
			final hex = Digest.make(input, d.alg).toHex();
			if (hex != d.hex) {
				matched = false;
				Sys.stderr().writeString('${d.alg} of the empty message: $hex\n');
			}
		}
	claim("empty digests match the empty message for every algorithm", matched);
	claim("digest input keeps length 0", stillEmpty(input));
}

function signatures() {
	final key = Key.readPEM(haxe.Resource.getString("key"), false);
	final input = Bytes.alloc(0);
	final signature = Digest.sign(input, key, SHA256);
	claim("signing keeps the input at length 0", stillEmpty(input));
	final checked = Bytes.alloc(0);
	claim("signature of the empty message verifies", Digest.verify(checked, signature, key, SHA256));
	claim("verifying keeps the input at length 0", stillEmpty(checked));
	claim("signature of the empty message does not verify a NUL byte", !Digest.verify(Bytes.alloc(1), signature, key, SHA256));
	final noSignature = Bytes.alloc(0);
	claim("an empty signature does not verify", !Digest.verify(Bytes.ofString("libhxcpp"), noSignature, key, SHA256));
	claim("verifying keeps an empty signature at length 0", stillEmpty(noSignature));
}

function der() {
	final privateDer = Bytes.alloc(0);
	final publicDer = Bytes.alloc(0);
	final certDer = Bytes.alloc(0);
	claim("an empty private key is refused", throws(() -> Key.readDER(privateDer, false)));
	claim("an empty public key is refused", throws(() -> Key.readDER(publicDer, true)));
	final chain = Certificate.fromString(haxe.Resource.getString("cert"));
	claim("an empty certificate is refused", throws(() -> chain.addDER(certDer)));
	claim("DER input keeps length 0", stillEmpty(privateDer) && stillEmpty(publicDer) && stillEmpty(certDer));
}

function send() {
	final cert = Certificate.fromString(haxe.Resource.getString("cert"));
	final key = Key.readPEM(haxe.Resource.getString("key"), false);
	final listener = new Socket();
	listener.verifyCert = false;
	listener.setCertificate(cert, key);
	listener.bind(new Host("127.0.0.1"), 0);
	listener.listen(1);
	final done = new Lock();
	var received:String = null;
	Thread.create(() -> {
		final peer = listener.accept();
		try {
			peer.handshake();
			final got = Bytes.alloc(5);
			peer.input.readFullBytes(got, 0, 5);
			received = got.toString();
		} catch (e:Dynamic) {
			Sys.stderr().writeString('peer: $e\n');
		}
		peer.close();
		done.release();
	});
	final client = new Socket();
	client.verifyCert = false;
	client.connect(new Host("127.0.0.1"), listener.host().port);
	final empty = Bytes.alloc(0);
	final written = client.output.writeBytes(empty, 0, 0);
	claim("sending nothing writes 0 bytes", written == 0);
	claim("sending nothing keeps the buffer at length 0", stillEmpty(empty));
	client.output.writeString("hello");
	client.output.flush();
	done.wait(30);
	claim("the stream carries what follows", received == "hello");
	client.close();
	listener.close();
}

function main() {
	digests();
	signatures();
	der();
	send();
}
