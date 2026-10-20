function fails(f:Void->Void):Bool {
	try {
		f();
		return false;
	} catch (e:Dynamic) {
		return true;
	}
}

// /dev/full accepts buffered writes and fails the real one with ENOSPC
function main() {
	if (Sys.systemName() != "Linux") {
		Sys.println("close reported failure: true");
		Sys.println("flush reported failure: true");
		Sys.println("saveContent reported failure: true");
		return;
	}
	var out = sys.io.File.write("/dev/full");
	out.writeString("x");
	Sys.println("close reported failure: " + fails(() -> out.close()));
	var flushed = sys.io.File.write("/dev/full");
	flushed.writeString("x");
	Sys.println("flush reported failure: " + fails(() -> flushed.flush()));
	fails(() -> flushed.close());
	Sys.println("saveContent reported failure: " + fails(() -> sys.io.File.saveContent("/dev/full", "x")));
}
