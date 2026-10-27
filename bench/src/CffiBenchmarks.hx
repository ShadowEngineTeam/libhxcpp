package;

/**
	CFFI calls from native code, the way an extension library makes them.
	The entry points are looked up through hx_cffi once, untimed; both
	runtimes export the same ones.
**/
@:cppFileCode('
extern "C" void *hx_cffi(const char *inName);
typedef hx::Object *(*BenchCallN)(hx::Object *, hx::Object **, int);
typedef const char *(*BenchValString)(hx::Object *);

static BenchCallN bench_callN = 0;
static BenchValString bench_val_string = 0;

static int bench_call_vector(Dynamic func, Dynamic a, Dynamic b, Dynamic c, int count)
{
	if (!bench_callN)
		bench_callN = (BenchCallN)hx_cffi("val_callN");
	hx::Object *args[3] = { a.mPtr, b.mPtr, c.mPtr };
	int sum = 0;
	for(int i=0;i<count;i++)
		sum += (int)Dynamic(bench_callN(func.mPtr, args, 3));
	return sum;
}

static int bench_string_views(Dynamic str, int count)
{
	if (!bench_val_string)
		bench_val_string = (BenchValString)hx_cffi("val_string");
	int sum = 0;
	for(int i=0;i<count;i++)
	{
		const unsigned char *s = (const unsigned char *)bench_val_string(str.mPtr);
		sum = sum * 31 + s[0] + s[1];
	}
	return sum;
}
')
class CffiNative {
	public static function callVector(func:Dynamic, a:Dynamic, b:Dynamic, c:Dynamic, count:Int):Int
		return untyped __cpp__('bench_call_vector({0}, {1}, {2}, {3}, {4})', func, a, b, c, count);

	public static function stringViews(str:Dynamic, count:Int):Int
		return untyped __cpp__('bench_string_views({0}, {1})', str, count);
}

/** val_callN with three arguments, the uniform call a CFFI library makes. **/
class CffiCallVector extends Benchmark {
	static inline var N = 1000000;

	final func:Dynamic = (a:Int, b:Int, c:Int) -> a + b + c;

	public function new() {
		super("cffi_call_vector", "calls", N);
	}

	override public function run():Int {
		// Small Ints are shared boxes, so no allocation per argument is timed
		return CffiNative.callVector(func, 1, 2, 3, N);
	}
}

/** val_string on one boxed non-ASCII string, as a library reading the same value again. **/
class CffiStringView extends Benchmark {
	static inline var N = 256;

	var str:Dynamic;

	public function new() {
		super("cffi_string_view", "string views", N);
	}

	override public function setup() {
		var b = new StringBuf();
		for (i in 0...65536)
			b.addChar(0x3bb);
		str = b.toString();
	}

	override public function run():Int {
		return CffiNative.stringViews(str, N);
	}
}
