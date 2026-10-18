// Std.isOfType(v, Enum) passed hx::ClassOf< ::Enum >(), and Enum was a typedef
// of hx::Class, so it was the Class class object and the test was the same as
// Std.isOfType(v, Class): every class and every enum was both. haxe.Serializer
// makes the Enum test, so it wrote an enum type as a class. The expected
// output is what Haxe's own interpreter prints. openfl/libhxcpp#3
enum SomeEnum {
	A;
	B(i:Int);
}

class Example {
	public function new() {}
}

class Main {
	static function report(label:String, v:Dynamic) {
		Sys.println(label + ": Class " + Std.isOfType(v, Class) + ", Enum " + Std.isOfType(v, Enum));
	}

	static function main() {
		report("a class", Example);
		report("an enum", SomeEnum);
		report("String", String);
		report("Math", Math);
		report("an instance", new Example());
		report("an enum value", SomeEnum.B(1));
		report("null", null);
		var serialized = haxe.Serializer.run(SomeEnum);
		Sys.println("serialized enum type: " + serialized);
		Sys.println("round trip: " + (haxe.Unserializer.run(serialized) == SomeEnum));
	}
}
