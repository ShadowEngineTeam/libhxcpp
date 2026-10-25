// Young entries, keys and values stored in large old maps are logged for
// the next minor collection to mark (libhxcpp #305). Each case changes an old
// map, collects, allocates over the freed space and checks every entry.
class Item {
	public var id:Int;
	public var name:String;
	public function new(id:Int) {
		this.id = id;
		name = "item" + id;
	}
}

class Main {
	static var ints:haxe.ds.IntMap<Item>;
	static var strings:haxe.ds.StringMap<Item>;
	static var objects:haxe.ds.ObjectMap<Item, Item>;
	static var keys:Array<Item>;

	static function fill():Void {
		ints = new haxe.ds.IntMap();
		strings = new haxe.ds.StringMap();
		objects = new haxe.ds.ObjectMap();
		keys = [];
		for (i in 0...4096) {
			ints.set(i, new Item(i));
			strings.set("key" + i, new Item(i));
			var k = new Item(i);
			keys.push(k);
			objects.set(k, new Item(i));
		}
	}

	static function minor():Void {
		cpp.vm.Gc.run(false);
		var junk = [for (i in 0...20000) new Item(-1)];
		junk = null;
		cpp.vm.Gc.run(false);
	}

	static function intsOk():Bool {
		for (k in ints.keys()) {
			var item = ints.get(k);
			if (item == null || item.name != "item" + item.id) return false;
		}
		return true;
	}

	static function stringsOk():Bool {
		for (k in strings.keys()) {
			var item = strings.get(k);
			if (item == null || item.name != "item" + item.id || k.substr(0, 3) != "key") return false;
		}
		return true;
	}

	static function main() {
		fill();
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.run(false);

		// Young values replacing old ones
		for (i in 0...8) ints.set(i * 500, new Item(100000 + i));
		minor();
		var replaced = intsOk();
		for (i in 0...8) if (ints.get(i * 500).id != 100000 + i) replaced = false;
		Sys.println("replaced values survive: " + replaced);

		// New entries, with young string keys
		for (i in 0...8) strings.set("key" + Std.string(10000 + i * 3), new Item(200000 + i));
		minor();
		var inserted = stringsOk();
		for (i in 0...8) if (strings.get("key" + Std.string(10000 + i * 3)).id != 200000 + i) inserted = false;
		Sys.println("new entries and keys survive: " + inserted);

		// Young object keys and values
		var youngKeys = [for (i in 0...8) new Item(300000 + i)];
		for (k in youngKeys) objects.set(k, new Item(k.id));
		youngKeys = null;
		minor();
		var objectsOk = true;
		var found = 0;
		for (k in objects.keys()) {
			var v = objects.get(k);
			if (v == null || v.id != k.id || k.name != "item" + k.id) objectsOk = false;
			if (k.id >= 300000) found++;
		}
		Sys.println("young object keys survive: " + (objectsOk && found == 8));

		// Enough new entries to rehash, and some removed
		for (i in 0...6000) ints.set(5000 + i, new Item(400000 + i));
		for (i in 0...100) ints.remove(5000 + i * 7);
		minor();
		Sys.println("rehash and removal keep every entry: " + intsOk());

		// Past the limit the map is remembered whole
		for (i in 0...4096) ints.set(i, new Item(500000 + i));
		minor();
		Sys.println("whole-map fallback keeps every entry: " + intsOk());

		cpp.vm.Gc.run(true);
		Sys.println("full collection keeps every entry: " + (intsOk() && stringsOk()));
	}
}
