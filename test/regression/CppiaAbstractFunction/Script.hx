abstract class Shape {
	public function new() {}

	public abstract function area():Float;

	public function describe():String {
		return "area " + area();
	}
}

class Square extends Shape {
	var side:Float;

	public function new(side:Float) {
		super();
		this.side = side;
	}

	public function area():Float {
		return side * side;
	}
}

class Script {
	static function main() {
		var shape:Shape = new Square(3);
		Sys.println("an abstract function dispatches to its override: " + (shape.area() == 9));
		Sys.println("a base method calls the override: " + (shape.describe() == "area 9"));
	}
}
