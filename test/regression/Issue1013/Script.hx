class Script {
	static function main() {
		var h:Holder = null;
		try {
			h.value = 30;
			Sys.println("field: no error");
		} catch (e:Dynamic) {
			Sys.println("field: caught");
		}
		try {
			h.height = 30;
			Sys.println("property: no error");
		} catch (e:Dynamic) {
			Sys.println("property: caught");
		}
		var d:Dynamic = null;
		try {
			d.load("x");
			Sys.println("dynamic: no error");
		} catch (e:Dynamic) {
			Sys.println("dynamic: caught");
		}
	}
}
