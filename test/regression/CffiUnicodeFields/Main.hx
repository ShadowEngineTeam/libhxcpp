@:cppFileCode('
extern "C" void *hx_cffi(const char *);
static Dynamic cffiRead(Dynamic object,String name) {
 typedef int (*Id)(const char *);
 typedef hx::Object *(*Field)(hx::Object *,int);
 static Id id=(Id)hx_cffi("val_id");
 static Field field=(Field)hx_cffi("val_field");
 hx::strbuf buffer;
 return Dynamic(field(object.mPtr,id(name.utf8_str(&buffer))));
}
static String cffiName(String name) {
 typedef int (*Id)(const char *);
 typedef hx::Object *(*Name)(int);
 static Id id=(Id)hx_cffi("val_id");
 static Name fieldName=(Name)hx_cffi("val_field_name");
 hx::strbuf buffer;
 return Dynamic(fieldName(id(name.utf8_str(&buffer))));
}
static void cffiWrite(Dynamic object,String name,Dynamic value) {
 typedef int (*Id)(const char *);
 typedef void (*Set)(hx::Object *,int,hx::Object *);
 static Id id=(Id)hx_cffi("val_id");
 static Set set=(Set)hx_cffi("alloc_field");
 hx::strbuf buffer;
 set(object.mPtr,id(name.utf8_str(&buffer)),value.mPtr);
}
')
class Main {
	static function main() {
		for (name in ["plain","caf\u00e9","\u65e5\u672c\u8a9e","emoji\u{1f600}"]) {
			var roundtrip:String=untyped __cpp__("cffiName({0})",name);
			Sys.println("field ID name roundtrip: "+(roundtrip==name));
			var object:Dynamic={};
			Reflect.setField(object,name,7);
			var read:Dynamic=untyped __cpp__("cffiRead({0},{1})",object,name);
			Sys.println("CFFI reads Haxe field: "+(read==7));
			untyped __cpp__("cffiWrite({0},{1},{2})",object,name,9);
			Sys.println("CFFI updates same field: "+(Reflect.field(object,name)==9));
			Sys.println("field count preserved: "+(Reflect.fields(object).length==1));
		}
		var fixed:Dynamic={"caf\u00e9":7};
		var read:Dynamic=untyped __cpp__("cffiRead({0},{1})",fixed,"caf\u00e9");
		Sys.println("CFFI reads fixed Unicode field: "+(read==7));
	}
}