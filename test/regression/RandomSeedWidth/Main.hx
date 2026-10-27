// The checksums are the 32-bit sequence Windows has always given: unsigned
// long is 32 bits there. LP64 platforms gave other values for negative seeds
// once the state refreshed, after the first 25 draws.
class Main {
	static function checksums(seed:Int) {
		var random = new cpp.Random();
		random.setSeed(seed);
		var prefix = 0;
		var complete = 0;
		for (i in 0...1000) {
			var value = random.int(0x40000000);
			if (i < 25) prefix = (prefix * 31 + value) | 0;
			complete = (complete * 31 + value) | 0;
		}
		Sys.stderr().writeString('seed $seed first 25: $prefix, first 1000: $complete\n');
		return [prefix, complete];
	}

	static function check(name:String, seed:Int, prefix:Int, complete:Int) {
		var got = checksums(seed);
		Sys.println(name + " seed replays the 32-bit sequence: " + (got[0] == prefix && got[1] == complete));
	}

	static function main() {
		check("positive", 1, 540419374, -1026272285);
		check("negative", -1, -63552061, 804254160);
		check("minimum", -2147483648, -1511606413, 1436670243);
	}
}
