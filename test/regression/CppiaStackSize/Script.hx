// Analyzer optimizations could merge the locals below and shrink the frames
@:analyzer(ignore)
class Script {
	// 16 Floats, which every function it is inlined into keeps in its frame
	static inline function locals(n:Float):Float {
		var a = n, b = a + 1, c = b + 1, d = c + 1, e = d + 1, f = e + 1, g = f + 1, h = g + 1;
		var i = h + 1, j = i + 1, k = j + 1, l = k + 1, m = l + 1, o = m + 1, p = o + 1, q = p + 1;
		return a + q;
	}

	// Each level holds 128 Floats, over 1 KB of script stack
	static function recurse(n:Int):Float {
		if (n == 0)
			return 0;
		return locals(n) + locals(n) + locals(n) + locals(n) + locals(n) + locals(n) + locals(n) + locals(n) + recurse(n - 1);
	}

	// Recurses through most of a script stack of this size, then through twice its size
	static function check(size:Int) {
		var fits = true;
		try {
			recurse(Std.int((size - 64 * 1024) / 1200));
		} catch (e:Dynamic) {
			fits = false;
		}
		Sys.println("recursion within the size: " + fits);
		var error = "none";
		try {
			recurse(Std.int(size / 512));
		} catch (e:Dynamic) {
			error = Std.string(e);
		}
		Sys.println("recursion past the size throws Stack Overflow: " + (error == "Stack Overflow"));
	}

	public static function main() {
		Host.checks.push(check);
		check(Host.size);
	}
}
