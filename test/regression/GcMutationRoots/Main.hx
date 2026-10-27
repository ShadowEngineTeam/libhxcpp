import cpp.vm.Gc;

class Node {
	public var value:Int;
	public var label:String;
	public var next:Node;

	public function new(value:Int, next:Node = null) {
		this.value = value;
		this.label = "node-" + value;
		this.next = next;
	}

	public function intact():Bool {
		return label == "node-" + value;
	}
}

class Main {
	static var root:Node;
	static var record:Dynamic;
	static var read:Void->Node;
	static var write:Node->Void;

	static function installClosures() {
		var captured = new Node(500);
		read = () -> captured;
		write = value -> captured = value;
	}

	static function main() {
		root = new Node(-1, new Node(73));
		record = {edge: new Node(700)};
		installClosures();
		Gc.run(true);

		var graphCorrect = true;
		var recordsCorrect = true;
		var closuresCorrect = true;
		for (round in 0...32) {
			// The only path to the original node moves through new holders.
			root.next = new Node(round, new Node(1000 + round, root.next));
			Reflect.setField(record, "edge", new Node(2000 + round, root.next));
			write(new Node(3000 + round, root.next));
			Gc.run((round & 3) == 0);

			var node = root.next;
			for (previous in 0...round + 1) {
				var expected = round - previous;
				if (node == null || !node.intact() || node.value != expected
					|| node.next == null || !node.next.intact() || node.next.value != 1000 + expected) {
					graphCorrect = false;
					break;
				}
				node = node.next.next;
			}
			if (node == null || !node.intact() || node.value != 73 || node.next != null)
				graphCorrect = false;

			var field:Node = Reflect.field(record, "edge");
			if (field == null || !field.intact() || field.value != 2000 + round || field.next != root.next)
				recordsCorrect = false;
			var captured = read();
			if (captured == null || !captured.intact() || captured.value != 3000 + round || captured.next != root.next)
				closuresCorrect = false;
		}

		Sys.println("rewired graphs retain older descendants: " + graphCorrect);
		Sys.println("reflective anonymous fields retain replacement graphs: " + recordsCorrect);
		Sys.println("mutable closure captures retain replacement graphs: " + closuresCorrect);
	}
}
