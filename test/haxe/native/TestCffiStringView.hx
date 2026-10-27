package native;

import utest.Test;
import utest.Assert;
import cpp.vm.Gc;
import sys.thread.Thread;

// val_string on a boxed non-ASCII string keeps the first UTF-8 conversion
// in the box instead of converting and allocating on every call
// (libhxcpp #322)
#if !cppia
@:cppFileCode('
extern "C" void *hx_cffi(const char *inName);
typedef const char *(*TestValString)(hx::Object *);
typedef char *(*TestValDupString)(hx::Object *);

static const char *testView(Dynamic inValue)
{
   static TestValString f = (TestValString)hx_cffi("val_string");
   return f(inValue.mPtr);
}

static bool testSameView(Dynamic inValue)
{
   return testView(inValue)==testView(inValue);
}

static ::String testViewText(Dynamic inValue)
{
   return ::String::create(testView(inValue));
}

// Changes a writable copy and reports whether the view is unchanged
static bool testDupIsSeparate(Dynamic inValue)
{
   static TestValDupString f = (TestValDupString)hx_cffi("val_dup_string");
   char *dup = f(inValue.mPtr);
   const char *v = testView(inValue);
   dup[0] = 33;
   return v!=dup && v[0]!=33;
}
')
#end
class TestCffiStringView extends Test
{
   #if !cppia
   static function lambdas(n:Int):String
   {
      var b = new StringBuf();
      for(i in 0...n)
         b.addChar(0x3bb);
      b.add("end");
      return b.toString();
   }

   static function viewText(v:Dynamic):String
      return untyped __cpp__('testViewText({0})', v);

   function testUnicodeViewIsCompleteUtf8()
   {
      var text = lambdas(4096);
      Assert.equals(text, viewText(text));
   }

   function testRepeatedViewsReuseOneConversion()
   {
      var boxed:Dynamic = lambdas(4096);
      Assert.isTrue(untyped __cpp__('testSameView({0})', boxed));
   }

   function testWritableDuplicateIsSeparate()
   {
      var boxed:Dynamic = lambdas(100);
      Assert.isTrue(untyped __cpp__('testDupIsSeparate({0})', boxed));
   }

   // The kept conversion is marked, and moved, with the box
   function testViewsSurviveCollection()
   {
      var views:Array<Dynamic> = [];
      for(i in 0...64)
      {
         var b:Dynamic = lambdas(i + 1);
         viewText(b);
         views.push(b);
      }
      for(i in 0...3)
         Gc.run(true);
      Gc.compact();
      var ok = true;
      for(i in 0...64)
         if (viewText(views[i])!=lambdas(i + 1))
            ok = false;
      Assert.isTrue(ok);
   }

   // Threads asking for the first view together all get the same text
   function testConcurrentFirstViews()
   {
      var shared:Dynamic = lambdas(100000);
      var expected = lambdas(100000);
      var main = Thread.current();
      for(t in 0...4)
         Thread.create(() -> main.sendMessage(viewText(shared)==expected));
      var ok = true;
      for(t in 0...4)
         if (Thread.readMessage(true)!=true)
            ok = false;
      Assert.isTrue(ok);
   }

   function testAsciiView()
   {
      var ascii:Dynamic = "plain ascii text";
      Assert.equals("plain ascii text", viewText(ascii));
   }
   #end
}
