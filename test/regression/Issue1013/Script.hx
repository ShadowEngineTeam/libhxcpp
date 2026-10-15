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
		var a:Array<Int> = null;
		try {
			a.push(1);
			Sys.println("array push: no error");
		} catch (e:Dynamic) {
			Sys.println("array push: caught");
		}
		try {
			var v = a[0];
			Sys.println("array read: no error");
		} catch (e:Dynamic) {
			Sys.println("array read: caught");
		}
		try {
			a[0] = 1;
			Sys.println("array write: no error");
		} catch (e:Dynamic) {
			Sys.println("array write: caught");
		}
	}
}
