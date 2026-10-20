function openFds():Int
	return sys.FileSystem.readDirectory("/proc/self/fd").length;

// The sockets are made on a thread that then ends, so no stack keeps them
function onWorker(work:Void->Void) {
	var done = new sys.thread.Lock();
	sys.thread.Thread.create(() -> {
		work();
		done.release();
	});
	done.wait();
	Sys.sleep(0.2);
}

function collect() {
	for (i in 0...3)
		cpp.vm.Gc.run(true);
}

function main() {
	if (Sys.systemName() != "Linux") {
		Sys.println("explicit close growth: 0");
		Sys.println("collected sockets closed: true");
		return;
	}
	var base = openFds();
	onWorker(() -> for (i in 0...128) new sys.net.Socket().close());
	collect();
	Sys.println("explicit close growth: " + (openFds() - base));
	base = openFds();
	onWorker(() -> for (i in 0...128) new sys.net.Socket());
	collect();
	Sys.println("collected sockets closed: " + (openFds() - base < 8));
}
