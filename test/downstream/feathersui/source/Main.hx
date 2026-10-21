import feathers.controls.Application;
import feathers.controls.Button;
import feathers.controls.Label;
import feathers.controls.ListView;
import feathers.controls.TextInput;
import feathers.data.ArrayCollection;
import feathers.layout.VerticalLayout;

class Main extends Application
{
	public function new()
	{
		super();
		layout = new VerticalLayout();
		var label = new Label("libhxcpp");
		addChild(label);
		var input = new TextInput();
		addChild(input);
		var list = new ListView();
		list.dataProvider = new ArrayCollection([for (i in 0...50) {text: 'Item $i'}]);
		list.itemToText = item -> item.text;
		addChild(list);
		var button = new Button("Add");
		button.addEventListener(openfl.events.MouseEvent.CLICK, _ -> label.text = input.text);
		addChild(button);
	}
}
