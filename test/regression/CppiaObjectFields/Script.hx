class Node {
	public var value:Int;
	public var next:Node;
	public var label:Dynamic;

	public function new(value:Int)
		this.value = value;
}

class Script {
	static function main() {
		var host = new HostThing();
		var head:Node = null;
		for (i in 0...20000) {
			var n = new Node(i);
			n.next = head;
			n.label = {index: i};
			head = n;
			if (i % 5000 == 0) {
				host.obj = new Node(-i);
				var captured = i;
				host.fn = () -> captured;
				host.items = [i, i + 1];
				cpp.vm.Gc.run(false);
			}
		}
		cpp.vm.Gc.run(false);
		cpp.vm.Gc.run(true);
		var count = 0;
		var labelsOk = true;
		var n = head;
		while (n != null) {
			if (n.label.index != n.value)
				labelsOk = false;
			count++;
			n = n.next;
		}
		var hostOk = (host.obj : Node).value == -15000 && host.fn() == 15000 && host.items[1] == 15001;
		Sys.println('script fields: ${count == 20000 && labelsOk}, host fields: $hostOk');
	}
}
