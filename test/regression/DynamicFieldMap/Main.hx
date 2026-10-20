@:cppFileCode('
static ::Dynamic sMap;
static void fill()
{
   for(int i=0;i<256;i++)
      __string_hash_set(sMap, HX_CSTRING("f") + ::String(i), i);
   __string_hash_set(sMap, HX_CSTRING("none"), null());
}
static ::Dynamic get(::String name, bool &found)
{
   ::Dynamic out = HX_CSTRING("untouched");
   found = ::hx::FieldMapGet(&sMap, name, out);
   return out;
}
static ::Dynamic getById(::String name, bool &found)
{
   ::Dynamic out = HX_CSTRING("untouched");
   found = ::hx::FieldMapGet(&sMap, __hxcpp_field_to_id(name.utf8_str()), out);
   return out;
}
static int sumReads(int rounds)
{
   int total = 0;
   ::Array< ::String > keys = ::Array_obj< ::String >::__new(0,256);
   for(int i=0;i<256;i++)
      keys->push(HX_CSTRING("f") + ::String(i));
   for(int r=0;r<rounds;r++)
      for(int i=0;i<256;i++)
      {
         ::Dynamic out;
         if (::hx::FieldMapGet(&sMap, keys[i], out))
            total += (int)out;
      }
   return total;
}
')
class Main {
	static function show(name:String, byId:Bool):String {
		var found = false;
		var value:Dynamic = byId ? untyped __cpp__('getById({0}, {1})', name, found) : untyped __cpp__('get({0}, {1})', name, found);
		return '$name: $found $value';
	}

	static function main() {
		untyped __cpp__('fill()');
		for (byId in [false, true]) {
			Sys.println(show("f7", byId));
			Sys.println(show("none", byId));
			Sys.println(show("missing", byId));
		}
		Sys.println((untyped __cpp__('sumReads(1)') : Int));
		var t0 = haxe.Timer.stamp();
		var total:Int = untyped __cpp__('sumReads(8000)');
		var ms = Math.round((haxe.Timer.stamp() - t0) * 1000);
		if (Sys.getEnv("SHOW_TIME") != null)
			Sys.println('2M reads: $ms ms ($total)');
	}
}
