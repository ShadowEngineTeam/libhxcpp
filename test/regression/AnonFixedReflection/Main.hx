function main() {
	var one = @:fixed {answer: 42};
	var two = @:fixed {a: 1, b: null};
	var five = @:fixed {a: 1, b: 2, c: 3, d: 4, e: 5};
	Sys.println(Reflect.field(one, "answer") + " " + Reflect.hasField(one, "answer") + " " + Reflect.fields(one).join(","));
	Sys.println(Reflect.hasField(two, "b") + " " + Reflect.hasField(two, "z"));
	var name = ["e", ""].join("");
	Sys.println(Reflect.hasField(five, "a") + " " + Reflect.hasField(five, name) + " " + Reflect.hasField(five, "f"));
}
