package native;

import utest.Test;
import utest.Assert;
import cpp.vm.Gc;

// val_callN and val_ocallN pass up to five arguments to the fixed-arity entry
// points instead of building an argument array for every call
// (libhxcpp #324). Every kind of callback sees the arguments it did before.
#if !cppia
@:cppFileCode('
extern "C" void *hx_cffi(const char *inName);
typedef hx::Object *(*TestCallN)(hx::Object *, hx::Object **, int);
typedef hx::Object *(*TestOCallN)(hx::Object *, int, hx::Object **, int);

static Dynamic testCallN(Dynamic inFunc, Array<Dynamic> inArgs)
{
   static TestCallN f = (TestCallN)hx_cffi("val_callN");
   hx::Object *args[8];
   for(int i=0;i<inArgs->length;i++)
      args[i] = inArgs[i].mPtr;
   return f(inFunc.mPtr, args, inArgs->length);
}

static Dynamic testOCallN(Dynamic inObj, ::String inField, Array<Dynamic> inArgs)
{
   static TestOCallN f = (TestOCallN)hx_cffi("val_ocallN");
   hx::Object *args[8];
   for(int i=0;i<inArgs->length;i++)
      args[i] = inArgs[i].mPtr;
   return f(inObj.mPtr, __hxcpp_field_to_id(inField.utf8_str()), args, inArgs->length);
}
')
#end
class TestCffiCallVector extends Test
{
   #if !cppia
   static function call(f:Dynamic, args:Array<Dynamic>):Dynamic
      return untyped __cpp__('testCallN({0}, {1})', f, args);

   static function ocall(o:Dynamic, field:String, args:Array<Dynamic>):Dynamic
      return untyped __cpp__('testOCallN({0}, {1}, {2})', o, field, args);

   static function opt(a:Int, ?b:Int, c:String = "c"):String
      return '$a,$b,$c';

   function testFixedArities()
   {
      var fixed:Array<Dynamic> = [
         () -> "0",
         (a) -> '$a',
         (a, b) -> '$a$b',
         (a, b, c) -> '$a$b$c',
         (a, b, c, d) -> '$a$b$c$d',
         (a, b, c, d, e) -> '$a$b$c$d$e',
         (a, b, c, d, e, f) -> '$a$b$c$d$e$f',
      ];
      for(n in 0...fixed.length)
      {
         var args:Array<Dynamic> = [for(i in 0...n) i + 1];
         Assert.equals(n==0 ? "0" : args.join(""), call(fixed[n], args));
      }
   }

   function testOptionalArguments()
   {
      Assert.equals("1,null,c", call(opt, [1]));
      Assert.equals("1,2,c", call(opt, [1, 2]));
      Assert.equals("1,2,x", call(opt, [1, 2, "x"]));
   }

   function testBoundMethodAndField()
   {
      var counter = new CallCounter(100);
      Assert.equals(106, call(counter.add, [1, 2, 3]));
      Assert.equals(106, ocall(counter, "add", [1, 2, 3]));
   }

   function testVariableArguments()
   {
      var count = Reflect.makeVarArgs(a -> a.length);
      for(n in 0...8)
         Assert.equals(n, call(count, [for(i in 0...n) i]));
   }

   function testCallbackException()
   {
      var threw = try {
         call((a, b) -> throw "boom", [1, 2]);
         false;
      } catch(e:String) e=="boom";
      Assert.isTrue(threw);
   }

   function testArgumentsSurviveCollection()
   {
      var result = call((a:Array<Int>, b:String) -> {
         Gc.run(true);
         Gc.compact();
         return a.length + b.length;
      }, [[1, 2, 3], "four"]);
      Assert.equals(7, result);
   }

   function testNullFunctionThrows()
   {
      Assert.raises(() -> call(null, [1]));
   }
   #end
}

class CallCounter
{
   public var base:Int;

   public function new(base:Int)
      this.base = base;

   public function add(a:Int, b:Int, c:Int):Int
      return base + a + b + c;
}
