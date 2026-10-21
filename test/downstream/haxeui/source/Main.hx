import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.ListView;
import haxe.ui.containers.VBox;
import haxe.ui.core.Screen;
import haxe.ui.data.ArrayDataSource;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		Toolkit.init();
		var box = new VBox();
		var label = new Label();
		label.text = "libhxcpp";
		box.addComponent(label);
		var input = new TextField();
		box.addComponent(input);
		var list = new ListView();
		var data = new ArrayDataSource<Dynamic>();
		for (i in 0...50)
			data.add({text: 'Item $i'});
		list.dataSource = data;
		box.addComponent(list);
		var button = new Button();
		button.text = "Add";
		button.onClick = _ -> label.text = input.text;
		box.addComponent(button);
		Screen.instance.addComponent(box);
	}
}
