class Main {
	static var module:cpp.cppia.Module;

	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		module = cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		module.boot();
		module.run();
	}
}
