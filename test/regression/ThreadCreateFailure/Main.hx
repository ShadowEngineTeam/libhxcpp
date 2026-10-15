// An impossible default stack size makes every new thread fail on glibc
@:cppFileCode('
#if defined(__linux__)
#include <pthread.h>
#include <stdint.h>
static bool makeThreadsFail()
{
	pthread_attr_t attr;
	pthread_attr_init(&attr);
	bool ok = pthread_attr_setstacksize(&attr, SIZE_MAX / 4 * 3)==0 && pthread_setattr_default_np(&attr)==0;
	pthread_attr_destroy(&attr);
	return ok;
}
#else
static bool makeThreadsFail() { return false; }
#endif
')
class Main {
	static function main() {
		cpp.vm.Gc.run(true);
		if (!untyped __cpp__("makeThreadsFail()")) {
			Sys.println("caught");
			return;
		}
		try {
			sys.thread.Thread.create(() -> {});
			Sys.println("no error");
		} catch (e:Dynamic) {
			Sys.println("caught");
		}
	}
}
