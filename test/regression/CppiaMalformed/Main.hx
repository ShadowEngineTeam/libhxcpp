function check(name:String, code:String) {
	try {
		cpp.cppia.Module.fromString(code);
		Sys.println('$name loaded');
	} catch (e:Dynamic) {
		Sys.println('$name threw');
	}
}

function main() {
	check("negative type count", "CPPIA 0 -1 0 NOMAIN RESOURCES 0 ");
	check("huge class count", "CPPIA 0 0 2000000000 NOMAIN RESOURCES 0 ");
	check("bad type id", "CPPIA 0 1 1 T 1 CLASS 5 0 0 0 NOMAIN RESOURCES 0 ");
	check("negative resource length", "CPPIA 1 1 a 0 0 NOMAIN RESOURCES 1 RESO 0 -5 x");
	check("valid", "CPPIA 0 0 0 NOMAIN RESOURCES 0 ");
}
