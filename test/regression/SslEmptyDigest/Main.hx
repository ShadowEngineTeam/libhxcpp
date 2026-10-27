import haxe.io.Bytes;
import sys.ssl.Digest;
import sys.ssl.DigestAlgorithm;

// Hashing an empty Bytes took its first element's address through the
// growing accessor, which resized the storage to one byte: the first call
// could hash that byte, and every later call did.
function main() {
	final input = Bytes.alloc(0);
	final first = Digest.make(input, DigestAlgorithm.SHA256).toHex();
	final second = Digest.make(input, DigestAlgorithm.SHA256).toHex();
	final expected = haxe.crypto.Sha256.make(Bytes.alloc(0)).toHex();
	Sys.stderr().writeString('first $first\nsecond $second\nexpected $expected\n');
	Sys.println("native digest preserves empty input storage: " + (input.length == 0 && input.getData().length == 0));
	Sys.println("first empty digest matches SHA256: " + (first == expected));
	Sys.println("repeated empty digest matches SHA256: " + (second == expected));
	final payload = Bytes.ofString("libhxcpp");
	Sys.println("nonempty digest matches SHA256: "
		+ (Digest.make(payload, DigestAlgorithm.SHA256).toHex() == haxe.crypto.Sha256.make(payload).toHex()));
}
