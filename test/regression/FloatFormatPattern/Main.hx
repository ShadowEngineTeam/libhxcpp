// __hxcpp_set_float_format sets the snprintf pattern for every Float to
// String. It used any string it was given, so a pattern with %s or %n read or
// wrote through the double as a pointer. It now accepts only a pattern with one
// floating-point conversion, and leaves the current one in place otherwise.
function setFormat(format:String):String {
	return try {
		untyped __global__.__hxcpp_set_float_format(format);
		"set";
	} catch (e:Dynamic) {
		"refused";
	}
}

function main() {
	Sys.println("%.3f: " + setFormat("%.3f") + " " + Std.string(Std.parseFloat("1.5")));
	for (format in ["%s", "%n", "%d", "%.3f%s", "%", "no conversion", "%f %f"])
		Sys.println(format + ": " + setFormat(format) + " " + Std.string(Std.parseFloat("1.5")));
	Sys.println("100%% %8.2e: " + setFormat("100%% %8.2e") + " " + Std.string(Std.parseFloat("1.5")));
}
