class Main {
	static function load(name:String):cpp.cppia.Module {
		var path=haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()),name+".cppia"]);
		var module=cpp.cppia.Module.fromData(sys.io.File.getBytes(path).getData());
		module.boot();
		module.run();
		return module;
	}

	static function main() {
		var a=load("a");
		Sys.println("first module resource: "+(haxe.Resource.getString("a")=="alpha"));
		var b=load("b");
		Sys.println("host resource remains: "+(haxe.Resource.getString("host")=="host"));
		Sys.println("first module still readable: "+(haxe.Resource.getString("a")=="alpha"));
		Sys.println("second module readable: "+(haxe.Resource.getString("b")=="beta"));
		var bytes=haxe.Resource.getBytes("a");
		Sys.println("first module bytes remain: "+(bytes!=null && bytes.toString()=="alpha"));
		var names=haxe.Resource.listNames();
		Sys.println("both modules enumerated: "+(names.indexOf("a")>=0 && names.indexOf("b")>=0));
		untyped b.release();
		Sys.println("first module remains after second release: "+(haxe.Resource.getString("a")=="alpha"));
		untyped a.release();
	}
}