function units(hex:String):String {
	var s = haxe.io.Bytes.ofHex(hex).toString();
	return [for (i in 0...s.length) StringTools.hex(s.charCodeAt(i), 4)].join(" ");
}

function main() {
	for (hex in ["e282ac", "c280", "dfbf", "e0a080", "ed9fbf", "ee8080", "efbfbf", "f0908080", "f48fbfbf", "c0af", "e080af", "8923", "e282", "f4908080", "eda080", "41c3"])
		Sys.println(hex + ": " + units(hex));
}
