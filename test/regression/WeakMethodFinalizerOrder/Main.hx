class Receiver {
	public function new() {}

	public function ping():Int
		return 73;
}

class Plain {
	public function new() {}
}

@:cppFileCode('
#include <thread>
#include <hx/Native.h>
struct ForwardAdapter : hx::LocalFunc {
 Dynamic wrapped;
 ForwardAdapter(Dynamic value) : wrapped(value) { HX_OBJ_WB_NEW_MARKED_OBJECT(this); }
 void *__GetHandle() const override { return wrapped.mPtr; }
 ::Dynamic __Run(const Array< ::Dynamic> &inArgs) override { return wrapped->__Run(inArgs); }
#if (HXCPP_API_LEVEL<500)
 Dynamic __run() override { return wrapped(); }
#endif
 int __ArgCount() const override { return 0; }
 void __Mark(hx::MarkContext *__inCtx) override { HX_MARK_MEMBER(wrapped); }
 #ifdef HXCPP_VISIT_ALLOCS
 void __Visit(hx::VisitContext *__inCtx) override { HX_VISIT_MEMBER(wrapped); }
 #endif
};
static Dynamic wrapAdapter(Dynamic value) { return Dynamic(new ForwardAdapter(value)); }
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone; worker.join();
}
')
class Main {
	static var receiver:Receiver;
	static var weak:cpp.vm.WeakRef<Dynamic>;
	static var weakAdapter:cpp.vm.WeakRef<Dynamic>;
	static var strong:Dynamic;
	static var weakCalls = 0;
	static var adapterCalls = 0;
	static var strongCalls = 0;
	static var plainCalls = 0;
	static var callable = false;
	static var adapterCallable = false;
	static var cleared = false;

	// Finalizers only count, so they touch nothing the collection freed
	static function weakFinalized(value:Dynamic):Void
		weakCalls++;

	static function adapterFinalized(value:Dynamic):Void
		adapterCalls++;

	static function strongFinalized(value:Dynamic):Void
		strongCalls++;

	static function plainFinalized(value:Plain):Void
		plainCalls++;

	static function populate():Void {
		receiver = new Receiver();
		var method:Dynamic = receiver.ping;
		cpp.vm.Gc.setFinalizer(method, cpp.Callable.fromStaticFunction(weakFinalized));
		weak = new cpp.vm.WeakRef(method);
		var adapter:Dynamic = untyped __cpp__("wrapAdapter({0})", receiver.ping);
		cpp.vm.Gc.setFinalizer(adapter, cpp.Callable.fromStaticFunction(adapterFinalized));
		weakAdapter = new cpp.vm.WeakRef(adapter);
		strong = receiver.ping;
		cpp.vm.Gc.setFinalizer(strong, cpp.Callable.fromStaticFunction(strongFinalized));
		var plain = new Plain();
		cpp.vm.Gc.setFinalizer(plain, cpp.Callable.fromStaticFunction(plainFinalized));
	}

	static function verify():Void {
		var method:Dynamic = weak.get();
		callable = method != null && method() == 73;
		var adapter:Dynamic = weakAdapter.get();
		adapterCallable = adapter != null && adapter() == 73;
	}

	static function release():Void {
		receiver = null;
		strong = null;
	}

	static function verifyReleased():Void
		cleared = weak.get() == null && weakAdapter.get() == null;

	// Minor collections first, which look at the young weak references and
	//  finalizers with HXCPP_GC_GENERATIONAL, then full ones, which look at the
	//  old ones too
	static function collect() {
		for (i in 0...2)
			cpp.vm.Gc.run(false);
		for (i in 0...3)
			cpp.vm.Gc.run(true);
	}

	static function main() {
		untyped __cpp__("runJoined({0})", populate);
		collect();
		untyped __cpp__("runJoined({0})", verify);
		Sys.println("weak callback remains callable with a live receiver: " + callable);
		Sys.println("preserved weak callback is not finalized: " + (weakCalls == 0));
		Sys.println("weak adapter remains callable with a live receiver: " + adapterCallable);
		Sys.println("preserved weak adapter is not finalized: " + (adapterCalls == 0));
		Sys.println("strong callback is not finalized: " + (strongCalls == 0));
		Sys.println("unreachable plain target finalizes once: " + (plainCalls == 1));
		untyped __cpp__("runJoined({0})", release);
		collect();
		untyped __cpp__("runJoined({0})", verifyReleased);
		Sys.println("released callbacks clear and finalize once: "
			+ (cleared && weakCalls == 1 && adapterCalls == 1 && strongCalls == 1 && plainCalls == 1));
		if (weakCalls != 1 || adapterCalls != 1)
			Sys.stderr().writeString('weak finalized $weakCalls, adapter finalized $adapterCalls\n');
	}
}
