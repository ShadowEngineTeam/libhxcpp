@:cppFileCode('
#if (HXCPP_API_LEVEL>=500)
static bool viewsOk()
{
	// Neither reinterpret nor a compare with an empty prefix reads the data,
	// so a small buffer stands in for a large one
	static unsigned char buffer[16];
	const int64_t size = INT64_C(4294967296);
	cpp::marshal::View<unsigned char> large(cpp::Pointer<unsigned char>(buffer), size);
	cpp::marshal::View<unsigned char> empty(cpp::Pointer<unsigned char>(buffer), 0);

	bool ok = large.reinterpret<uint16_t>().length == size / 2;
	ok = ok && large.reinterpret<uint64_t>().length == size / 8;
	ok = ok && large.reinterpret<uint16_t>().reinterpret<unsigned char>().length == size;
	ok = ok && empty.compare(large) < 0 && large.compare(empty) > 0 && empty.compare(empty) == 0;
	return ok;
}
#else
static bool viewsOk() { return true; }
#endif
')
class Main {
	static function main() {
		var ok:Bool = untyped __cpp__('viewsOk()');
		Sys.println("wide views keep their lengths: " + ok);
	}
}
