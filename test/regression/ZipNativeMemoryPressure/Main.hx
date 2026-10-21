class Main {
	static function collect():Float {
		for (i in 0...3)
			cpp.vm.Gc.run(true);
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
	}

	@:analyzer(ignore)
	static function abandon() {
		for (i in 0...256)
			new haxe.zip.Compress(6);
	}

	static function main() {
		var baseline = collect();
		var streams = [for (i in 0...256) new haxe.zip.Compress(6)];
		var inflaters = [for (i in 0...64) new haxe.zip.Uncompress(15)];
		var packed = haxe.zip.Compress.run(haxe.io.Bytes.ofString("libhxcpp"), 9);
		for (u in inflaters)
			u.execute(packed, 0, haxe.io.Bytes.alloc(64), 0);
		var growth = collect() - baseline;
		Sys.println("native compression memory accounted: " + (growth > 16 * 1024 * 1024));
		for (stream in streams)
			stream.close();
		for (u in inflaters)
			u.close();
		Sys.println("released by close: " + (collect() - baseline < 1024 * 1024));
		var text = [for (i in 0...2000) "libhxcpp " + i].join(",");
		var c = new haxe.zip.Compress(9);
		c.setFlushMode(haxe.zip.FlushMode.FINISH);
		var out = haxe.io.Bytes.alloc(text.length + 1024);
		var r = c.execute(haxe.io.Bytes.ofString(text), 0, out, 0);
		c.close();
		Sys.println("round trip: " + (haxe.zip.Uncompress.run(out.sub(0, r.write)).toString() == text));
		abandon();
		Sys.println("released by finalizers: " + (collect() - baseline < 1024 * 1024));
	}
}
