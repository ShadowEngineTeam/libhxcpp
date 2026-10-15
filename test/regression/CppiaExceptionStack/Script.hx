class Script {
	static function inner():Void {
		throw "script";
	}

	static function nullPush():Void {
		var a:Array<Int> = null;
		a.push(1);
	}

	static function catchScript() {
		try inner() catch (e:Dynamic) {}
	}

	static function catchNative() {
		try nullPush() catch (e:Dynamic) {}
	}

	static function check(thrower:String, catcher:String) {
		var stack = Std.string(haxe.CallStack.exceptionStack());
		Sys.println(stack.indexOf(thrower) >= 0 && stack.indexOf(catcher) < 0);
	}

	public static function main() {
		catchScript();
		check("inner", "catchScript");
		catchNative();
		check("nullPush", "catchNative");
	}
}
