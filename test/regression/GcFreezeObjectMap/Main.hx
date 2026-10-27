import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

class Key {
	public var id:Int;

	public function new(id:Int)
		this.id = id;
}

class Graph {
	public var keys:Array<Key>;
	public var objects:ObjectMap<Key, Int>;
	public var strings:StringMap<Int>;
	public var ints:IntMap<Int>;

	public function new() {
		keys = [];
		objects = new ObjectMap();
		strings = new StringMap();
		ints = new IntMap();
		for (i in 0...16) {
			var key = new Key(i);
			keys.push(key);
			objects.set(key, 100 + i);
			strings.set("key" + i, 100 + i);
			ints.set(i, 100 + i);
		}
	}
}

class Main {
	static function freeze<T>(value:T):T
		return untyped __cpp__("_hx_gc_freeze({0})", value);

	// Keys reached through the graph's array, not through the map
	static function checkObjects(graph:Graph):Bool {
		for (i in 0...16)
			if (!graph.objects.exists(graph.keys[i]) || graph.objects.get(graph.keys[i]) != 100 + i)
				return false;
		return true;
	}

	static function checkOwnKeys(graph:Graph):Bool {
		var count = 0;
		for (key in graph.objects.keys()) {
			if (graph.objects.get(key) != 100 + key.id)
				return false;
			count++;
		}
		return count == 16;
	}

	static function checkKeys(graph:Graph):Bool {
		var count = 0;
		for (key in graph.objects.keys()) {
			if (key.id < 0 || key.id >= 16 || graph.keys[key.id] != key)
				return false;
			count++;
		}
		return count == 16;
	}

	static function checkScalar(graph:Graph):Bool {
		for (i in 0...16)
			if (graph.strings.get("key" + i) != 100 + i || graph.ints.get(i) != 100 + i)
				return false;
		return true;
	}

	static function main() {
		var original = new Graph();
		var frozen = freeze(original);
		Sys.println("original object-map lookups remain correct: " + checkObjects(original));
		Sys.println("frozen map keys share identity with copied graph keys: " + checkKeys(frozen));
		Sys.println("frozen object-map lookups remain correct: " + checkObjects(frozen));
		Sys.println("frozen object-map lookups by its own keys remain correct: " + checkOwnKeys(frozen));
		Sys.println("frozen string and integer map controls remain correct: " + checkScalar(frozen));
		cpp.vm.Gc.compact();
		Sys.println("frozen object-map lookups survive collection: " + (checkObjects(frozen) && checkOwnKeys(frozen) && checkObjects(original)));
	}
}
