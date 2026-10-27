// oninit declared before the other functions
class HostSprite extends HostBase {
	public function oninit():Void
		log.push("host oninit");

	public function update_sprite():Void
		log.push("update_sprite");

	public function some_function():Void
		log.push("some_function");

	override public function update(elapsed:Float):Void
		super.update(elapsed);

	override public function draw():Void
		log.push("draw");
}
