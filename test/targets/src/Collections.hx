// Arrays, maps, objects and enums, printed in an order every target shares:
// map keys and object fields are sorted first.
enum Shape {
	Circle(r:Float);
	Rect(w:Int, h:Int);
	Empty;
}

class Collections {
	static function p(label:String, value:Dynamic)
		Out.println(label + ": " + Std.string(value));

	static function sorted<T>(it:Iterator<T>):Array<T> {
		var a = [for (x in it) x];
		a.sort(Reflect.compare);
		return a;
	}

	public static function run() {
		var a = [5, 3, 8, 1];
		p("slice", [a.slice(1), a.slice(-2), a.slice(1, -1), a.slice(3, 1), a.slice(99)]);
		var b = a.copy();
		p("splice", [b.splice(1, 2), b]);
		b = a.copy();
		p("splice negative", [b.splice(-2, 1), b, a.copy().splice(1, -1), a.copy().splice(99, 1)]);
		b = a.copy();
		b.insert(-1, 9);
		b.insert(99, 7);
		b.insert(-99, 0);
		p("insert", b);
		b = [1, 2, 3, 2];
		p("remove", [b.remove(2), b, b.remove(9), b.indexOf(2), b.lastIndexOf(2), b.indexOf(3, -1), b.lastIndexOf(1, -9)]);
		b = a.copy();
		b.sort((x, y) -> x - y);
		p("sort", b);
		p("concat join", [a.concat([0]).join("-"), [].join(","), [null, 1].join(",")]);
		p("map filter", [a.map(x -> x * 2), a.filter(x -> x > 3)]);
		p("reverse unshift", {
			var c = a.copy();
			c.reverse();
			c.unshift(-1);
			c.push(10);
			[c, c.shift(), c.pop(), c.length];
		});
		var sparse = [1];
		sparse[4] = 5;
		p("sparse", [sparse.length, sparse[0], sparse[4]]);
		var resized = [1, 2, 3, 4];
		resized.resize(2);
		p("resize", resized);
		p("contains", [a.contains(8), a.contains(9)]);

		var m = new Map<String, Int>();
		for (k in ["b", "a", "é", "😀", ""])
			m.set(k, k.length);
		p("string map", [for (k in sorted(m.keys())) '$k=${m.get(k)}']);
		p("string map ops", [m.exists("a"), m.exists("z"), m.get("z"), m.remove("a"), m.remove("a")]);
		var im = new Map<Int, String>();
		for (k in [3, -1, 0, 100000, 0x7fffffff])
			im.set(k, Std.string(k));
		p("int map", [for (k in sorted(im.keys())) k]);
		p("int map copy", [for (k in sorted(im.copy().keys())) k].length);

		var o:Dynamic = {b: 1, a: "x", c: null};
		var fields = Reflect.fields(o);
		fields.sort(Reflect.compare);
		p("fields", fields);
		p("field ops", [Reflect.field(o, "a"), Reflect.hasField(o, "c"), Reflect.hasField(o, "z"), Reflect.field(o, "z")]);
		Reflect.setField(o, "d", 4);
		Reflect.deleteField(o, "b");
		fields = Reflect.fields(o);
		fields.sort(Reflect.compare);
		p("field changes", fields);
		p("compare", [Reflect.compare(1, 2), Reflect.compare("b", "a"), Reflect.compare(1.5, 1.5)]);

		var shapes = [Circle(1.5), Rect(2, 3), Empty];
		p("enums", shapes);
		p("enum ops", [Type.enumIndex(Rect(1, 1)), Type.enumConstructor(Circle(1)), Type.enumParameters(Rect(4, 5)), Type.enumEq(Rect(1, 2), Rect(1, 2)), Empty == Empty]);
		p("enum switch", [for (s in shapes) switch s {
			case Circle(r): 'circle $r';
			case Rect(w, h) if (w < h): 'tall $w';
			case Rect(_, _): 'rect';
			case Empty: 'empty';
		}]);

		var list = new haxe.ds.List<Int>();
		list.add(1);
		list.push(0);
		list.add(2);
		p("List", [list.length, list.first(), list.last(), list.remove(1), Lambda.array(list)]);
		var vec = new haxe.ds.Vector<Int>(3);
		vec[1] = 5;
		p("Vector", [vec.length, vec[1]]);
	}
}
