@:cppFileCode('
static int liveCounted = 0;
#if (HXCPP_API_LEVEL>=500)
struct Counted
{
	int v;
	Counted() : v(0) { liveCounted++; }
	Counted(int x) : v(x) { liveCounted++; }
	Counted(const Counted &o) : v(o.v) { liveCounted++; }
	~Counted() { liveCounted--; }
};

static void fillBoxes()
{
	for (int i = 0; i < 1000; i++)
	{
		Counted c(i);
		new ::cpp::marshal::Boxed_obj<Counted>();
		new ::cpp::marshal::Boxed_obj<Counted>(&c);
		new ::cpp::marshal::Boxed_obj<Counted>(i);
		new ::cpp::marshal::Boxed_obj<int>(i);
		new ::cpp::marshal::Boxed_obj<int *>();
	}
}
#else
static void fillBoxes() {}
#endif
')
class Main {
	@:analyzer(ignore)
	static function fill() {
		untyped __cpp__('fillBoxes()');
	}

	static function main() {
		fill();
		for (i in 0...5)
			cpp.vm.Gc.run(true);
		var live:Int = untyped __cpp__('liveCounted');
		Sys.println("native boxed values destroyed: " + (live >= 0 && live <= 30));
	}
}
