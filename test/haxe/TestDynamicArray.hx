import utest.Test;
import utest.Assert;

class TestDynamicArray extends Test
{
   // push appends numbers and strings without boxing them, through the
   // backing array's typed set
   public function testPushValues()
   {
      var ints:Array<Dynamic> = [];
      var lengths = [for(i in 0...5) ints.push(i * 1000 + 7)];
      Assert.same([1, 2, 3, 4, 5], lengths);
      Assert.same([7, 1007, 2007, 3007, 4007], ints);

      var strings:Array<Dynamic> = [];
      strings.push("a");
      strings.push("b" + strings.length);
      Assert.same(["a", "b1"], strings);

      var many:Array<Dynamic> = [];
      for(i in 0...100000)
         many.push(i + 1000);
      var sum = 0.0;
      for(v in many)
         sum += v;
      Assert.equals(100000, many.length);
      Assert.equals(5099950000.0, sum);
   }

   public function testPushSpecialFloats()
   {
      var floats:Array<Dynamic> = [];
      floats.push(1.5);
      floats.push(-0.0);
      floats.push(Math.NaN);
      floats.push(Math.POSITIVE_INFINITY);
      floats.push(Math.NEGATIVE_INFINITY);
      var negZero:Float = floats[1];
      var nan:Float = floats[2];
      Assert.equals(1.5, floats[0]);
      Assert.equals(Math.NEGATIVE_INFINITY, 1 / negZero);
      Assert.isTrue(Math.isNaN(nan));
      Assert.equals(Math.POSITIVE_INFINITY, floats[3]);
      Assert.equals(Math.NEGATIVE_INFINITY, floats[4]);
   }

   public function testPushWidens()
   {
      var widened:Array<Dynamic> = [];
      widened.push(1);
      widened.push(2.5);
      widened.push(3);
      Assert.same([1, 2.5, 3], widened);

      var mixed:Array<Dynamic> = [];
      mixed.push(1);
      mixed.push("two");
      mixed.push(true);
      mixed.push(null);
      mixed.push(4.5);
      Assert.same([1, "two", true, null, 4.5], mixed);

      var big = haxe.Int64.make(0x12345678, 0x9abcdef0);
      var int64s:Array<Dynamic> = [];
      int64s.push(5);
      int64s.push(big);
      int64s.push(6);
      var back:haxe.Int64 = int64s[1];
      Assert.isTrue(back == big);
      Assert.equals(3, int64s.length);
   }

   public function testPushSharedTypedArray()
   {
      var typed:Array<Int> = [1, 2];
      var shared:Array<Dynamic> = cast typed;
      Assert.equals(3, shared.push(3));
      shared.push(4.75);
      Assert.same([1, 2, 3, 4], typed);

      var floatsTyped:Array<Float> = [0.5];
      var sharedFloats:Array<Dynamic> = cast floatsTyped;
      sharedFloats.push(2);
      Assert.same([0.5, 2.0], floatsTyped);
   }
}
