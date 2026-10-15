function main() {
	try {
		final s = new sys.thread.Semaphore(150000000);
		Sys.println(s.tryAcquire() ? "acquired" : "not acquired");
	} catch (e:Dynamic) {
		Sys.println('threw $e');
	}
}
