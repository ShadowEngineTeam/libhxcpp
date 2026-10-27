package;

import Benchmark.Rng;

class Corpus {
	public static final words = [
		"alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel", "india", "juliet", "kilo", "lima", "mike", "november",
		"oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "xray", "yankee", "zulu", "the", "of",
		"and", "to", "in", "is", "that", "for", "it", "as", "was", "with", "be", "by", "on", "not", "he", "this", "are", "or", "his",
		"from", "at", "which", "but", "have", "an", "had", "they", "you", "were", "their", "one", "all", "we", "can", "her", "has",
	];

	/** About 12 KB of words separated by spaces, the same every time. **/
	public static function text(count:Int, seed:Int):String {
		var rng = new Rng(seed);
		var b = new StringBuf();
		for (i in 0...count) {
			if (i > 0)
				b.addChar(32);
			b.add(words[rng.below(words.length)]);
		}
		return b.toString();
	}
}

/** StringBuf appends of words, spaces and Ints, turned into a String every 64 rounds. **/
class StringBuild extends Benchmark {
	static inline var N = 1200000;

	public function new() {
		super("string_build", "appends", N * 3);
	}

	override public function run():Int {
		var words = Corpus.words;
		var total = 0;
		var b = new StringBuf();
		for (i in 0...N) {
			b.add(words[i & 63]);
			b.addChar(32);
			b.add(i);
			if ((i & 63) == 63) {
				var s = b.toString();
				var last:Int = s.charCodeAt(s.length - 1);
				total = (total * 31 + s.length + last) | 0;
				b = new StringBuf();
			}
		}
		return total;
	}
}

/** indexOf from spread-out start positions; about half the needles are found. **/
class StringIndex extends Benchmark {
	static inline var N = 250000;

	var text:String;
	final needles:Array<String> = [];

	public function new() {
		super("string_index", "indexOf calls", N);
	}

	override public function setup() {
		text = Corpus.text(2000, 99);
		for (w in Corpus.words) {
			needles.push(w + " " + w.charAt(0));
			needles.push("q" + w);
		}
	}

	override public function run():Int {
		var sum = 0;
		var len = text.length;
		for (i in 0...N) {
			var at = text.indexOf(needles[i % needles.length], (i * 7919) % len);
			sum = (sum + at) | 0;
		}
		return sum;
	}
}

/** substr of short slices, read back with charCodeAt. **/
class StringSubstr extends Benchmark {
	static inline var N = 10000000;

	var text:String;

	public function new() {
		super("string_substr", "substr calls", N);
	}

	override public function setup() {
		text = Corpus.text(2000, 7);
	}

	override public function run():Int {
		var sum = 0;
		var limit = text.length - 16;
		for (i in 0...N) {
			var s = text.substr((i * 31) % limit, 1 + (i & 15));
			var first:Int = s.charCodeAt(0);
			sum = (sum + s.length + first) | 0;
		}
		return sum;
	}
}

/** split of a text on spaces. **/
class StringSplit extends Benchmark {
	static inline var N = 2000;

	var text:String;

	public function new() {
		super("string_split", "split calls", N);
	}

	override public function setup() {
		text = Corpus.text(2000, 11);
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var parts = text.split(" ");
			sum = (sum + parts.length + parts[i % parts.length].length) | 0;
		}
		return sum;
	}
}

/** toUpperCase and toLowerCase of a 64-character line. **/
class StringCase extends Benchmark {
	static inline var N = 3000000;

	final lines:Array<String> = [];

	public function new() {
		super("string_case", "case conversions", N);
	}

	override public function setup() {
		var text = Corpus.text(2000, 13);
		for (i in 0...64)
			lines.push(text.substr(i * 97, 64));
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var line = lines[i & 63];
			var s = (i & 1) == 0 ? line.toUpperCase() : line.toLowerCase();
			var c:Int = s.charCodeAt(i & 63);
			sum = (sum + c) | 0;
		}
		return sum;
	}
}

/**
	split and lastIndexOf with a multipart-style boundary: a run of dashes
	and a token, in a text that also holds rules of dashes.
**/
class StringLongNeedle extends Benchmark {
	static inline var N = 400;

	var text:String;
	var boundary:String;

	public function new() {
		super("string_long_needle", "searches", N * 2);
	}

	override public function setup() {
		var dashes = new StringBuf();
		for (i in 0...200)
			dashes.addChar("-".code);
		var rule = dashes.toString();
		boundary = rule.substr(0, 70) + "boundary7MA4YWxk";
		var b = new StringBuf();
		for (part in 0...16) {
			b.add(boundary);
			b.add("\r\nContent-Type: text/plain\r\n\r\n");
			for (line in 0...40) {
				b.add(Corpus.text(8, part * 64 + line));
				b.add("\r\n");
				b.add(rule);
				b.add("\r\n");
			}
		}
		b.add(boundary);
		b.add("--\r\n");
		text = b.toString();
	}

	override public function run():Int {
		var sum = 0;
		for (i in 0...N) {
			var parts = text.split(boundary);
			sum = (sum + parts.length + parts[1 + (i % 16)].length) | 0;
			sum = (sum + text.lastIndexOf(boundary, text.length - 1 - i * 50)) | 0;
		}
		return sum;
	}
}

/** Std.parseInt and Std.parseFloat on lines that start with a number and go on in non-ASCII text. **/
class ParseNumbers extends Benchmark {
	static inline var N = 1000000;

	final intLines:Array<String> = [];
	final floatLines:Array<String> = [];

	public function new() {
		super("parse_numbers", "parses", N * 2);
	}

	override public function setup() {
		var notes = ["Zürich ⇒ Genève, prix réduit", "東京から大阪まで", "Größe × Breite ≈ Fläche", "Ελληνικά κείμενα"];
		for (i in 0...64) {
			var note = notes[i & 3] + " " + Corpus.text(10, i + 1);
			intLines.push((i * 7919) + "\t" + note);
			floatLines.push((i * 31.25) + "\t" + note);
		}
	}

	override public function run():Int {
		var sum = 0;
		var fsum = 0.0;
		for (i in 0...N) {
			var v:Null<Int> = Std.parseInt(intLines[i & 63]);
			if (v != null) {
				var iv:Int = v;
				sum = (sum + iv) | 0;
			}
			fsum += Std.parseFloat(floatLines[i & 63]);
		}
		return (sum + Std.int(fsum)) | 0;
	}
}
