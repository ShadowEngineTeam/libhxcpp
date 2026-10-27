class ClientSprite extends HostSprite {
	override public function oninit():Void
		log.push("script oninit");

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		update_sprite();
	}
}

class ClientSpriteReordered extends HostSpriteReordered {
	override public function oninit():Void
		log.push("script oninit");

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		update_sprite();
	}
}

class Script {
	static function main() {}
}
