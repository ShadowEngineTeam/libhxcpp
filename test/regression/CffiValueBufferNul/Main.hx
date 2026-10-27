// val_buffer appends the text of a value to a CFFI buffer. It measured the
// text with strlen, so everything after a NUL was lost (libhxcpp #393)
@:cppFileCode('
extern "C" void *hx_cffi(const char *);
static Array<unsigned char> appendRenderedValue(Dynamic value) {
	typedef void *(*Alloc)(const char *);
	typedef void (*AppendValue)(void *, hx::Object *);
	typedef int (*Size)(void *);
	typedef const char *(*Data)(void *);
	Alloc alloc = (Alloc)hx_cffi("alloc_buffer");
	AppendValue append = (AppendValue)hx_cffi("val_buffer");
	Size size = (Size)hx_cffi("buffer_size");
	Data data = (Data)hx_cffi("buffer_data");
	Array_obj<unsigned char> * volatile buffer = (Array_obj<unsigned char> *)alloc("prefix:");
	append(buffer, value.mPtr);
	int length = size(buffer);
	Array<unsigned char> output(length, length);
	if (length) memcpy(output->GetBase(), data(buffer), length);
	return output;
}
')
class Main {
	static function rendered(value:Dynamic):haxe.io.Bytes {
		return haxe.io.Bytes.ofData(untyped __cpp__("appendRenderedValue({0})", value));
	}

	static function main() {
		var intact = true;
		for (value in ["left\x00right", "\x00start", "end\x00", "Ā\x00tail"]) {
			var got = rendered(value);
			if (got.compare(haxe.io.Bytes.ofString("prefix:" + value)) != 0) {
				Sys.stderr().writeString('${haxe.io.Bytes.ofString(value).toHex()}: got ${got.toHex()}\n');
				intact = false;
			}
		}
		Sys.println("rendered strings preserve embedded NUL bytes: " + intact);
		Sys.println("ordinary text remains intact: " + (rendered("plain").toString() == "prefix:plain"));
		Sys.println("non-ASCII text remains intact: " + (rendered("Ā中").toString() == "prefix:Ā中"));
		Sys.println("an empty string appends nothing: " + (rendered("").toString() == "prefix:"));
		Sys.println("null values retain their representation: " + (rendered(null).toString() == "prefix:null"));
	}
}
