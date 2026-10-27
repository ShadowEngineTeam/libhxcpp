// Built twice by run.sh: with Embind, as executables link by default, a
// function bound with EMSCRIPTEN_BINDINGS can be called through Module, and
// with HXCPP_LINK_NO_EMBIND (and no_bindings here), the program runs without
// it (libhxcpp #336)
#if !no_bindings
@:cppFileCode('
#include <emscripten/bind.h>
static int add(int a, int b) { return a + b; }
EMSCRIPTEN_BINDINGS(embind_test) { emscripten::function("add", &add); }
')
#end
class Main
{
   static function thrower(n:Int):Int
   {
      if (n == 0)
         throw "bottom " + n;
      return thrower(n - 1) + 1;
   }

   static function main()
   {
      #if !no_bindings
      var sum:Int = untyped __cpp__('emscripten::val::module_property("add")(2, 3).as<int>()');
      Sys.println('bound function called: ${sum == 5}');
      #end

      var kept = [for (i in 0...1000) "string " + i];
      var caught = try { thrower(100); null; } catch (e:String) e;
      cpp.vm.Gc.run(true);
      var intact = true;
      for (i in 0...kept.length)
         if (kept[i] != "string " + i)
            intact = false;
      Sys.println('exception caught: ${caught == "bottom 0"}');
      Sys.println('strings kept: $intact');
   }
}
