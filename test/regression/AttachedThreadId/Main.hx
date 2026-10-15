@:cppFileCode('
#include <thread>
#include <hx/thread/Thread.hpp>
static int attachedThreadId()
{
	int result = -1;
	std::thread t([&]() {
		int top = 0;
		hx::SetTopOfStack(&top, true);
		result = hx::thread::Thread_obj::id();
		hx::SetTopOfStack((int *)0, true);
	});
	hx::EnterGCFreeZone();
	t.join();
	hx::ExitGCFreeZone();
	return result;
}
')
class Main {
	static function main() {
		var mainId:Int = untyped __cpp__("hx::thread::Thread_obj::id()");
		var attached:Int = untyped __cpp__("attachedThreadId()");
		Sys.println('main $mainId');
		Sys.println('attached thread has its own id: ${attached != mainId && attached > 0}');
	}
}
