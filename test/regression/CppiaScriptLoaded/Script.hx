class Script {
	static var booted = init();

	static function init() {
		Sys.println("script booted");
		return true;
	}

	static function main() {
		Sys.println("script ran: " + Util.twice(21));
	}
}
