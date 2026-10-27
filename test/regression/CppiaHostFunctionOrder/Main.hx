// HaxeFoundation/hxcpp#818: a script class extending a host class called the
// wrong function, depending on the order of the host class's functions. The
// host calls oninit once, then update and draw each frame, as a game does.
class Main {
	static var keep:Array<Dynamic> = [HostSprite, HostSpriteReordered];

	static function main() {
		var path = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "script.cppia"]);
		var bytes = sys.io.File.getBytes(path);
		for (jit in [false, true]) {
			cpp.cppia.Host.enableJit(jit);
			var module = cpp.cppia.Module.fromData(bytes.getData());
			module.boot();
			module.run();
			for (name in ["ClientSprite", "ClientSpriteReordered"]) {
				var sprite:HostBase = Type.createInstance(module.resolveClass(name), []);
				if (Std.isOfType(sprite, HostSprite))
					(cast sprite : HostSprite).oninit();
				else
					(cast sprite : HostSpriteReordered).oninit();
				for (frame in 0...2) {
					sprite.update(1 / 60);
					sprite.draw();
				}
				var log = sprite.log.join(", ");
				var expected = "script oninit, update_sprite, draw, update_sprite, draw";
				if (log != expected)
					Sys.stderr().writeString('$name: $log\n');
				Sys.println('jit $jit: $name runs its oninit once, then update_sprite and draw each frame: ${log == expected}');
			}
			untyped module.release();
		}
	}
}
