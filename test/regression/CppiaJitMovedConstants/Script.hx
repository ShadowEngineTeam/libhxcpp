enum Constant {
	First;
	Second;
}

// The JIT used to embed these objects' addresses in its code, and the moving
// collector moves them
class Script {
	static function literal():Dynamic {
		return "a boxed string literal";
	}

	static function constant():Constant {
		return Second;
	}

	static function position(?pos:haxe.PosInfos):String {
		return pos.methodName;
	}

	static function main() {
		var ok = true;
		for (round in 0...30) {
			var churn = [for (i in 0...20000) [i, round]];
			churn = null;
			cpp.vm.Gc.run(true);
			// Fill the space the moved objects left
			var refill = [for (i in 0...20000) Std.string(i * round)];
			if (literal() != "a boxed string literal")
				ok = false;
			if (constant() != Second)
				ok = false;
			if (position() != "main")
				ok = false;
			refill = null;
		}
		Sys.println(ok ? "constants ok" : "constants moved");
	}
}
