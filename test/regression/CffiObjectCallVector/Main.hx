@:cppFileCode('
#include <vector>
extern "C" void *hx_cffi(const char *inName);
typedef hx::Object *(*OCallN)(hx::Object *, int, hx::Object **, int);

static Dynamic ocallN(Dynamic obj, String field, Array<Dynamic> args)
{
   OCallN f = (OCallN)hx_cffi("val_ocallN");
   std::vector<hx::Object *> vals;
   for(int i=0;i<args->length;i++)
      vals.push_back(args[i].mPtr);
   return f(obj.mPtr, __hxcpp_field_to_id(field.utf8_str()), vals.empty() ? 0 : &vals[0], (int)vals.size());
}
')
class Main {
	static function call(obj:Dynamic, field:String, args:Array<Dynamic>):Dynamic
		return untyped __cpp__('ocallN({0}, {1}, {2})', obj, field, args);

	static function main() {
		var obj:Dynamic = {
			count: Reflect.makeVarArgs(a -> a.length),
			sum: Reflect.makeVarArgs(a -> {
				var s = 0;
				for (x in a)
					s += x;
				s;
			})
		};
		Sys.println(call(obj, "count", []));
		Sys.println(call(obj, "count", [7]));
		Sys.println(call(obj, "count", [1, 2, 3]));
		Sys.println(call(obj, "sum", [1, 2, 3]));
		try {
			call(null, "count", []);
			Sys.println("no throw");
		} catch (e:Dynamic) {
			Sys.println("throws");
		}
	}
}
