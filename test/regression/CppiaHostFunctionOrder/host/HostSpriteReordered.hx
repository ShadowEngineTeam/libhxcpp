// The same class with oninit declared after some_function
class HostSpriteReordered extends HostBase {
	public function update_sprite():Void
		log.push("update_sprite");

	public function some_function():Void
		log.push("some_function");

	public function oninit():Void
		log.push("host oninit");

	override public function update(elapsed:Float):Void
		super.update(elapsed);

	override public function draw():Void
		log.push("draw");
}
