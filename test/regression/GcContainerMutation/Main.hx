import cpp.vm.Gc;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

class Node {
	public var value:Int;
	public var label:String;

	public function new(value:Int) {
		this.value = value;
		label = "payload-" + value;
	}

	public function isValue(expected:Int):Bool {
		return value == expected && label == "payload-" + expected;
	}
}

class Main {
	static var values:Array<Node>;
	static var keys:Array<Node>;
	static var ints = new IntMap<Node>();
	static var strings = new StringMap<Node>();
	static var objects = new ObjectMap<Node, Node>();

	static function main() {
		values = [for (i in 0...20000) new Node(i)];
		var expected = [for (i in 0...20000) i];
		Gc.run(true);
		var arraysCorrect = true;
		for (round in 0...8) {
			values.splice(17, 257);
			expected.splice(17, 257);
			values.insert(1024, new Node(90000 + round));
			expected.insert(1024, 90000 + round);

			// Save expected source values before the overlapping copy.
			var source = [for (i in 0...1024) expected[1000 + i]];
			cpp.NativeArray.blit(values, 500, values, 1000, 1024);
			for (i in 0...source.length)
				expected[500 + i] = source[i];

			var oldLength = values.length;
			values.resize(oldLength + 500);
			for (i in 0...500) {
				var id = 100000 + round * 500 + i;
				values[oldLength + i] = new Node(id);
				expected.push(id);
			}
			Gc.run((round & 1) == 0);
			if (values.length != expected.length)
				arraysCorrect = false;
			for (i in 0...expected.length) {
				if (values[i] == null || !values[i].isValue(expected[i]))
					arraysCorrect = false;
			}
		}

		keys = [for (i in 0...8192) new Node(i)];
		for (i in 0...1024) {
			ints.set(i, new Node(i));
			strings.set("key-" + i, new Node(10000 + i));
			objects.set(keys[i], new Node(20000 + i));
		}
		Gc.run(true);
		for (i in 0...8192) {
			ints.set(i, new Node(30000 + i));
			strings.set("key-" + i, new Node(40000 + i));
			objects.set(keys[i], new Node(50000 + i));
			if ((i & 511) == 511)
				Gc.run(false);
		}
		for (i in 0...8192) {
			if (i % 7 == 0) {
				ints.remove(i);
				strings.remove("key-" + i);
				objects.remove(keys[i]);
			}
		}
		Gc.run(true);

		var mapsCorrect = true;
		var removalsCorrect = true;
		for (i in 0...8192) {
			if (i % 7 == 0) {
				if (ints.exists(i) || strings.exists("key-" + i) || objects.exists(keys[i]))
					removalsCorrect = false;
			} else {
				var intValue = ints.get(i);
				var stringValue = strings.get("key-" + i);
				var objectValue = objects.get(keys[i]);
				if (intValue == null || !intValue.isValue(30000 + i)
					|| stringValue == null || !stringValue.isValue(40000 + i)
					|| objectValue == null || !objectValue.isValue(50000 + i))
					mapsCorrect = false;
			}
		}
		Sys.println("resized and overlapping pointer arrays preserve payloads: " + arraysCorrect);
		Sys.println("rehash and replacement preserve managed map values: " + mapsCorrect);
		Sys.println("removed entries stay absent after collection: " + removalsCorrect);
	}
}
