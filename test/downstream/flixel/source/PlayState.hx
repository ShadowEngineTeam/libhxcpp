import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var dots:FlxTypedGroup<FlxSprite>;

	override public function create()
	{
		super.create();
		dots = new FlxTypedGroup<FlxSprite>();
		for (i in 0...200)
		{
			var s = new FlxSprite(FlxG.random.float(0, 620), FlxG.random.float(0, 460));
			s.makeGraphic(8, 8, FlxColor.fromHSB(i * 1.8, 0.8, 1));
			s.velocity.set(FlxG.random.float(-80, 80), FlxG.random.float(-80, 80));
			dots.add(s);
		}
		add(dots);
		var t = new FlxText(0, 200, 640, "libhxcpp", 32);
		t.alignment = CENTER;
		add(t);
		FlxTween.tween(t, {y: 240}, 1, {type: PINGPONG});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		dots.forEach(s -> {
			if (s.x < 0 || s.x > 632) s.velocity.x *= -1;
			if (s.y < 0 || s.y > 472) s.velocity.y *= -1;
		});
	}
}
