@:cppFileCode('#include <hx/thread/ThreadLocal.hpp>')
class Main {
	// Each value is held only by this thread's slot for a ThreadLocal that is dropped at once
	@:analyzer(ignore)
	static function fill():Array<cpp.vm.WeakRef<Array<Int>>> {
		var refs = [];
		for (i in 0...20) {
			var payload = new Array<Int>();
			for (j in 0...1000)
				payload.push(j);
			refs.push(new cpp.vm.WeakRef(payload));
			var value:Dynamic = payload;
			untyped __cpp__('(new ::hx::thread::ThreadLocal_obj())->set({0})', value);
		}
		return refs;
	}

	static function main() {
		var refs = fill();
		for (i in 0...5)
			cpp.vm.Gc.run(true);
		var alive = refs.filter(r -> r.get() != null).length;
		Sys.println("values of collected ThreadLocals released: " + (alive <= 2));
	}
}
