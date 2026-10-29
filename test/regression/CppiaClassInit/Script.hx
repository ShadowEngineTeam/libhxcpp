class Script {
	static var started:String;

	static function __init__() {
		started = "ran";
	}

	static function main() {
		Sys.println("a script class's __init__ loads and runs: " + (started == "ran"));
	}
}
