function main() {
	var values = [1, 2, 3];
	var filtered = values.filter(v -> {
		values[v - 1] = v * 10;
		true;
	});
	Sys.println("direct: " + filtered.join(",") + " source " + values.join(","));
	var reflectedValues = [1, 2, 3];
	var filter:Dynamic = Reflect.field(reflectedValues, "filter");
	var reflected:Array<Int> = filter(v -> {
		reflectedValues[v - 1] = v * 10;
		true;
	});
	Sys.println("reflected: " + reflected.join(",") + " source " + reflectedValues.join(","));
	var names = ["a", "b"];
	var dyn:Dynamic = names;
	var kept:Array<String> = dyn.filter(s -> {
		names[names.indexOf(s)] = s.toUpperCase();
		true;
	});
	Sys.println("dynamic: " + kept.join(",") + " source " + names.join(","));
}
