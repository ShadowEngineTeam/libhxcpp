import cpp.cppia.Host;
import cpp.cppia.Module;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.BytesData;

// A host can teach the cppia loader other script formats: it registers a magic
// and a function that translates a script starting with it to cppia. Then
// Module.fromData and fromString load such a script, and Host.runFile, and so a
// stock host's command line, runs it, interpreted and with the JIT.
extern class CppiaFormats {
	@:native("__scriptable_cppia_register_format")
	static function register(magic:String, translate:Null<(script:BytesData) -> Dynamic>):Void;
}

class Main {
	static var translations = 0;
	static var cppia:Bytes;

	static function payload(script:BytesData):String {
		translations++;
		var b = Bytes.ofData(script);
		return b.getString(5, b.length - 5);
	}

	// "HIDE " and the cppia in base64, translated to bytes
	static function hidden(script:BytesData):Dynamic
		return Base64.decode(payload(script)).getData();

	// "TEXT " and cppia text, translated to a String
	static function text(script:BytesData):Dynamic
		return payload(script);

	static function failing(script:BytesData):Dynamic {
		payload(script);
		throw "cannot translate";
	}

	// Translates to a script in another registered format
	static function nested(script:BytesData):Dynamic {
		payload(script);
		return hide(cppia).getData();
	}

	static function hide(b:Bytes):Bytes
		return Bytes.ofString("HIDE " + Base64.encode(b));

	static function load(data:Bytes) {
		var module = Module.fromData(data.getData());
		module.boot();
		module.run();
	}

	static function error(f:() -> Void):Dynamic {
		try {
			f();
		} catch (e:Dynamic) {
			return e;
		}
		return null;
	}

	static function main() {
		var dir = haxe.io.Path.directory(Sys.programPath());
		cppia = sys.io.File.getBytes(haxe.io.Path.join([dir, "script.cppia"]));
		var hiddenFile = haxe.io.Path.join([dir, "script.hidden"]);
		sys.io.File.saveBytes(hiddenFile, hide(cppia));

		CppiaFormats.register("HIDE ", hidden);
		CppiaFormats.register("TEXT ", text);
		CppiaFormats.register("FAIL ", failing);
		CppiaFormats.register("LOOP ", nested);

		load(hide(cppia));
		Sys.println('Module.fromData loads a script in a registered format: ${translations == 1}');

		var module = Module.fromString("TEXT " + cppia.toString());
		module.boot();
		module.run();
		Sys.println('Module.fromString loads one, and a translator can return text: ${translations == 2}');

		for (jit in [false, true]) {
			Host.enableJit(jit);
			var before = translations;
			Host.runFile(hiddenFile);
			Sys.stderr().writeString('jit active: ${untyped __cpp__("__scriptable_cppia_jit_active()")}\n');
			Sys.println('Host.runFile runs one${jit ? " with the jit" : ", interpreted"}: ${translations == before + 1}');
		}
		Host.enableJit(false);

		var before = translations;
		load(cppia);
		Sys.println('cppia loads without a translator: ${translations == before}');

		before = translations;
		var e = error(() -> load(Bytes.ofString("FAIL x")));
		Sys.println('a translator\'s exception reaches the caller: ${e == "cannot translate" && translations == before + 1}');

		before = translations;
		e = error(() -> load(Bytes.ofString("LOOP x")));
		Sys.println('what a translator returns is loaded as cppia, not translated again: ${e != null && translations == before + 1}');

		e = error(() -> load(Bytes.ofString("NONE x")));
		Sys.println('a script in an unregistered format does not load: ${e != null && StringTools.contains(Std.string(e), "Bad magic")}');

		e = error(() -> CppiaFormats.register("", text));
		Sys.println('an empty magic is refused: ${e != null}');

		CppiaFormats.register("HIDE ", null);
		before = translations;
		e = error(() -> load(hide(cppia)));
		Sys.println('a removed format does not load: ${e != null && translations == before}');

		CppiaFormats.register("HIDE ", hidden);
		load(hide(cppia));
		Sys.println('registering it again brings it back: ${translations == before + 1}');
	}
}
