// A container allocated as a large object (4000 bytes or more) must still have its members marked
@:headerCode('
struct BigObj : public ::hx::Object
{
   enum { N = 600 };
   ::hx::Object *refs[N];
   inline void *operator new(size_t inSize) { return ::hx::InternalNew(inSize, true); }
   void __Mark(::hx::MarkContext *__inCtx) HXCPP_OVERRIDE { for(int i=0;i<N;i++) HX_MARK_OBJECT(refs[i]); }
   #ifdef HXCPP_VISIT_ALLOCS
   void __Visit(::hx::VisitContext *__inCtx) HXCPP_OVERRIDE { for(int i=0;i<N;i++) HX_VISIT_OBJECT(refs[i]); }
   #endif
};
')
class Main {
	static var holder:Dynamic;

	static function fill(i:Int):Dynamic {
		return [i * 7, i * 7 + 1, i * 7 + 2];
	}

	static function check(a:Dynamic, i:Int):Bool {
		var arr:Array<Int> = a;
		return arr.length == 3 && arr[0] == i * 7 && arr[1] == i * 7 + 1 && arr[2] == i * 7 + 2;
	}

	static function child(i:Int):Dynamic {
		return untyped __cpp__('Dynamic(((BigObj *)::Main_obj::holder.mPtr)->refs[{0}])', i);
	}

	public static function main() {
		untyped __cpp__('BigObj *b = new BigObj(); for(int i=0;i<BigObj::N;i++) b->refs[i] = 0; ::Main_obj::holder = Dynamic(b)');
		for (i in 0...600) {
			var d = fill(i);
			untyped __cpp__('((BigObj *)::Main_obj::holder.mPtr)->refs[{0}] = {1}.mPtr', i, d);
		}
		cpp.vm.Gc.run(true);
		var unmarked = 0;
		for (i in 0...600) {
			var marked:Bool = untyped __cpp__('(((unsigned char *)((BigObj *)::Main_obj::holder.mPtr)->refs[{0}])[HX_ENDIAN_MARK_ID_BYTE] == ::hx::gByteMarkID)', i);
			if (!marked)
				unmarked++;
		}
		Sys.println("unmarked children " + unmarked);
		var junk = [];
		for (round in 0...20) {
			cpp.vm.Gc.run(true);
			for (k in 0...20000)
				junk.push([k, k, k, k]);
			junk = [];
		}
		var bad = 0;
		for (i in 0...600)
			if (!check(child(i), i))
				bad++;
		Sys.println("corrupt children " + bad);
	}
}
