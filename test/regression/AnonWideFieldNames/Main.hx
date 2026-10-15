function main() {
	var small:Dynamic = {"ü": 1, b: 2};
	var big:Dynamic = {"ü": 1, b: 2, c: 3, d: 4, e: 5, f: 6, "été": 7};
	for (o in [small, big]) {
		Sys.println(Reflect.field(o, "ü"));
		Sys.println(Reflect.hasField(o, "ü"));
		Reflect.setField(o, "ü", 10);
		Sys.println(Reflect.field(o, "ü"));
		Sys.println(Reflect.fields(o).length);
	}
	Sys.println(Reflect.field(big, "été"));
	Sys.println(Reflect.field(big, "étè"));
	Sys.println(Reflect.field(big, ["ét", "é"].join("")));
	var parsed:Dynamic = haxe.Json.parse('{"ü": 1, "b": 2}');
	Sys.println(Reflect.field(parsed, "ü"));
}
