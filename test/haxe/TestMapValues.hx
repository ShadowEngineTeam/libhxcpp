import utest.Test;
import utest.Assert;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

class MapValueKey
{
   public var id:Int;
   public function new(inId:Int) id = inId;
}

// String and object-keyed map entries keep the hash beside the value
// (libhxcpp #370). Each value type, through growth, removal, iteration and
// collections, and a map that changes value type as it goes.
class TestMapValues extends Test
{
   static inline var N = 5000;

   static function key(i:Int) return "key_" + StringTools.hex(i * 2579);

   // Inlined, so each value type uses its own typed map store
   inline function check<T>(make:Int->T)
   {
      var values = [for(i in 0...N) make(i)];
      var smap = new StringMap<T>();
      var keys = [for(i in 0...N) new MapValueKey(i)];
      var omap = new ObjectMap<MapValueKey,T>();
      for(i in 0...N)
      {
         smap.set(key(i), values[i]);
         omap.set(keys[i], values[i]);
      }
      cpp.vm.Gc.run(true);
      cpp.vm.Gc.compact();
      for(i in 0...(N >> 1))
      {
         smap.remove(key(i * 2));
         omap.remove(keys[i * 2]);
      }
      var ok = true;
      for(i in 0...N)
      {
         var expected:Dynamic = (i & 1)==0 ? null : values[i];
         if (smap.get(key(i))!=expected || omap.get(keys[i])!=expected)
            ok = false;
      }
      var count = 0;
      for(v in smap)
         count++;
      for(k in omap.keys())
         if (omap.get(k)!=values[k.id])
            ok = false;
      Assert.isTrue(ok);
      Assert.equals(N >> 1, count);
   }

   function testIntValues() check(i -> i * 3);
   function testFloatValues() check(i -> i + 0.25);
   function testStringValues() check(i -> "v" + i);
   function testDynamicValues() check((i:Int) -> (i==7 ? null : ({ v: i } : Dynamic)));
   function testBoolValues() check(i -> (i % 3)==0);

   // A Dynamic map starts with Int values, then turns into one of strings
   function testValueTypeChange()
   {
      var m = new StringMap<Dynamic>();
      for(i in 0...N)
         m.set(key(i), i);
      m.set(key(0), "now a string");
      cpp.vm.Gc.run(true);
      Assert.equals("now a string", m.get(key(0)));
      Assert.equals(N - 1, m.get(key(N - 1)));
      m.set(key(1), 1.5);
      Assert.equals(1.5, m.get(key(1)));
   }
}
