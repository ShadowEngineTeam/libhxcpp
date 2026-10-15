function main() {
	Sys.println("\u0131".toUpperCase() == "I");
	Sys.println("k\u0131rm\u0131z\u0131".toUpperCase() == "KIRMIZI");
	Sys.println("\u0130STANBUL".toLowerCase() == "istanbul");
	var m = ["KIRMIZI" => 1];
	Sys.println(m.get("k\u0131rm\u0131z\u0131".toUpperCase()));
	Sys.println(switch ("\u0131".toUpperCase()) { case "I": "matched"; case _: "missed"; });
	Sys.println("caf\u00E9".toUpperCase() == "CAF\u00C9");
}
