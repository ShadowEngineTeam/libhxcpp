class Main {
	static function main() {
		var random = new cpp.Random();
		random.setSeed(12345);
		var upper = false;
		var inRange = true;
		for (i in 0...4096) {
			var value = random.int(0x7fffffff);
			if (value < 0 || value >= 0x7fffffff) inRange = false;
			if (value >= 0x40000000) upper = true;
		}
		Sys.println("draws stay in range: " + inRange);
		Sys.println("large bound reaches upper half: " + upper);
	}
}
