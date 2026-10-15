interface Shape {}

function attempt(name:String, f:Void->Dynamic) {
	try {
		f();
		Sys.println('$name returned');
	} catch (e:Dynamic) {
		Sys.println('$name threw');
	}
}

function main() {
	attempt("createInstance(Int)", () -> Type.createInstance(cast Type.resolveClass("Int"), []));
	attempt("createEmptyInstance(Shape)", () -> Type.createEmptyInstance(Shape));
	attempt("createInstance(Math)", () -> Type.createInstance(cast Math, []));
}
