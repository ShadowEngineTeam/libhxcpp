import haxe.io.Bytes;

// Encodings, parsers and serialisers that every target should agree on
class Formats {
	static function p(label:String, value:Dynamic)
		Out.println(label + ": " + Std.string(value));

	public static function run() {
		var text = "aé😀";
		var bytes = Bytes.ofString(text);
		p("utf8 bytes", [bytes.length, bytes.toHex(), bytes.getString(0, bytes.length), Bytes.ofHex("616263").toString()]);
		var b = Bytes.alloc(8);
		b.setInt32(0, -2);
		b.setUInt16(4, 0xabcd);
		b.set(6, 300);
		p("bytes access", [b.getInt32(0), b.getUInt16(4), b.get(6), b.toHex(), b.sub(4, 2).toHex(), b.compare(Bytes.alloc(8)) > 0, Bytes.alloc(2).compare(b) < 0]);
		b.setFloat(0, 1.5);
		b.setDouble(0, -0.25);
		p("bytes floats", [b.getDouble(0), b.getFloat(4) == b.getFloat(4)]);
		var out = new haxe.io.BytesOutput();
		out.writeInt32(7);
		out.writeString("hi");
		out.writeFloat(2.5);
		var input = new haxe.io.BytesInput(out.getBytes());
		p("streams", [input.readInt32(), input.readString(2), input.readFloat(), input.position]);
		p("base64", [haxe.crypto.Base64.encode(bytes), haxe.crypto.Base64.decode("YcOp8J+YgA==").toString(), haxe.crypto.Base64.encode(Bytes.ofString("ab"), false)]);
		p("md5 sha1", [haxe.crypto.Md5.encode(text), haxe.crypto.Sha1.encode(text), haxe.crypto.Sha256.encode(text)]);
		p("crc adler", [haxe.crypto.Crc32.make(bytes), haxe.crypto.Adler32.make(bytes)]);

		var json = haxe.Json.parse('{"b":[1,2.5,"x",null,true],"a":{"c":"é\\u00e9\\n"},"n":-0.5e2}');
		p("json read", [json.b, json.a.c, json.n, Reflect.fields(json).length]);
		p("json write", [haxe.Json.stringify([1, "a\"b", null, true, 2.5]), haxe.Json.stringify("é😀\t"), haxe.Json.stringify({x: 1})]);

		var r = ~/(\d+)-(\w+)/;
		p("ereg match", [r.match("ab 12-cd ef"), r.matched(0), r.matched(1), r.matchedLeft(), r.matchedRight(), r.matchedPos().pos, r.matchedPos().len]);
		p("ereg replace", [~/a/g.replace("banana", "o"), ~/(\w)(\w)/g.replace("abcd", "$2$1"), ~/é/.replace("héé", "e"), ~/x*/g.replace("abc", "-")]);
		p("ereg split", [~/\s*,\s*/g.split("a , b,c ,d"), ~/,/.split("a,b,c")]);
		p("ereg map", ~/\d/g.map("a1b22", e -> "[" + e.matched(0) + "]"));
		p("ereg unicode", [~/é+/.match("aéé"), ~/😀/.match("x😀"), ~/^.$/.match("😀")]);

		var s = new haxe.Serializer();
		s.serialize([1, 2.5, "é", null, true]);
		s.serialize(-0x80000000);
		var ser = s.toString();
		p("serialize", ser);
		var u = new haxe.Unserializer(ser);
		p("unserialize", [u.unserialize(), u.unserialize()]);

		var d = Date.fromTime(1700000000000.0);
		p("date utc", [DateTools.format(Date.fromTime(d.getTime() + d.getTimezoneOffset() * 60000), "%Y-%m-%d %H:%M:%S"), d.getTime()]);
		p("date parse", Date.fromString("2024-02-29 13:45:00").getDate());
	}
}
