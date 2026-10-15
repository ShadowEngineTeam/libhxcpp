import haxe.io.Bytes;

class Main {
	static function check(name:String, f:Void->Void) {
		try {
			f();
			Sys.println('$name no throw');
		} catch (e:Dynamic) {
			Sys.println('$name threw');
		}
	}

	static function main() {
		check("vector", () -> new haxe.ds.Vector<Float>(536870928));
		check("bytes blit", () -> Bytes.alloc(16).blit(2147483647, Bytes.alloc(4), 0, 1));
		check("native blit", () -> cpp.NativeArray.blit([1, 2, 3, 4], 2147483647, [5], 0, 1));
		check("index", () -> {
			var a = [1];
			a[2147483647] = 2;
		});
		check("join", () -> {
			var s = Bytes.alloc(1 << 24).toString();
			[for (i in 0...257) s].join("");
		});
	}
}
