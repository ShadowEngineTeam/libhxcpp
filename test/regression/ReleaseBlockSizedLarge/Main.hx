// Releasing a buffer that sits in a GC block but is as big as a large
// allocation. InternalNew rounds 3997 to 3999 bytes up to 4000 after it has
// chosen a block, and a realloc then released that block object as if it
// were a large allocation: when the large recycle list had room, part of the
// block was queued and passed to free by the next collection, corrupting the
// heap (libhxcpp #257, found by test/fuzz).
//
// urlEncode reserves its byte array to the string's length, 3998 here, and
// grows it for the UTF-8 form, releasing the first buffer. The large buffers
// around it start collections and give the recycle list room.
function main() {
	var text = [for (i in 0...3980) "a"].join("") + [for (i in 0...18) String.fromCharCode(0x4e2d)].join("");
	var total = 0;
	for (i in 0...400) {
		for (k in 0...40)
			total += haxe.io.Bytes.alloc(8000 + ((i + k) & 63) * 4).length;
		total += StringTools.urlEncode(text).length;
	}
	Sys.println('done ${total > 0}');
}
