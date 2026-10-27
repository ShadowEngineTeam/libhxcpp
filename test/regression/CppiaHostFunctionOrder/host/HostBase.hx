// Stands in for FlxSprite: a host base whose functions the host class overrides
class HostBase {
	public var log:Array<String> = [];

	public function new() {}

	public function update(elapsed:Float):Void {}

	public function draw():Void {}
}
