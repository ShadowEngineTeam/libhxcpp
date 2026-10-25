// Young values stored in large old arrays are logged for the next minor
// collection to mark (libhxcpp #301). Each case stores young objects or
// strings, moves them within the array or overwrites them, collects, then
// checks every value after allocating over the freed space.
class Item {
	public var id:Int;
	public var name:String;
	public function new(id:Int) {
		this.id = id;
		name = "item" + id;
	}
}

class Main {
	static var items:Array<Item>;
	static var names:Array<String>;
	static var small:Array<Item>;

	static function fill():Void {
		items = [for (i in 0...4096) new Item(i)];
		names = [for (i in 0...4096) "old" + i];
		small = [for (i in 0...1000) new Item(i)];
	}

	static function churn():Void {
		// Reuses whatever a collection freed
		var junk = [for (i in 0...20000) new Item(-1)];
		junk = null;
	}

	static function minor():Void {
		cpp.vm.Gc.run(false);
		churn();
		cpp.vm.Gc.run(false);
	}

	static function itemsOk():Bool {
		for (i in 0...items.length) {
			var item = items[i];
			if (item == null || item.name != "item" + item.id) return false;
		}
		return true;
	}

	static function main() {
		fill();
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.run(false);

		// A few young values, then moved by sort, insert, splice and blit
		for (i in 0...8) items[i * 500] = new Item(100000 + i);
		items.sort((a, b) -> b.id - a.id);
		items.insert(7, new Item(200000));
		items.splice(3, 2);
		untyped __cpp__("{0}->blit(100, {0}, 0, 50)", items);
		minor();
		Sys.println("moved young values survive: " + itemsOk());

		// Overwritten before the collection: the last value is the one kept
		for (r in 0...4) items[10] = new Item(300000 + r);
		minor();
		Sys.println("overwritten slot keeps its last value: " + (items[10].id == 300003 && itemsOk()));

		// Young strings
		for (i in 0...8) names[i * 300] = "young" + Std.string(i * 7);
		minor();
		var stringsOk = true;
		for (i in 0...8) if (names[i * 300] != "young" + Std.string(i * 7)) stringsOk = false;
		Sys.println("young strings survive: " + stringsOk);

		// Past the limit the array is remembered whole
		for (i in 0...items.length) items[i] = new Item(400000 + i);
		minor();
		Sys.println("whole-array fallback keeps every value: " + itemsOk());

		// An array below the length the log starts at
		for (i in 0...10) small[i * 90] = new Item(500000 + i);
		minor();
		var smallOk = true;
		for (i in 0...10) if (small[i * 90].id != 500000 + i) smallOk = false;
		Sys.println("small array keeps its young values: " + smallOk);

		// Two threads storing into the same old array
		var done = new sys.thread.Lock();
		for (t in 0...2) sys.thread.Thread.create(() -> {
			for (i in 0...200) items[t * 2000 + i] = new Item(600000 + t * 1000 + i);
			done.release();
		});
		done.wait();
		done.wait();
		minor();
		var threadsOk = itemsOk();
		for (t in 0...2) for (i in 0...200) if (items[t * 2000 + i].id != 600000 + t * 1000 + i) threadsOk = false;
		Sys.println("stores from two threads survive: " + threadsOk);

		cpp.vm.Gc.run(true);
		Sys.println("full collection keeps every value: " + itemsOk());
	}
}
