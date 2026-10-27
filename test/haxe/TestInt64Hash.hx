import haxe.Int64;
import utest.Test;
import utest.Assert;

// The runtime's Int64-keyed hash, which Haxe 4.3 has no Map class for
// (Haxe 5's Int64Map calls the same functions)
class Int64Table
{
   var h:Dynamic;

   public function new() {}

   public function set(key:Int64, value:Int):Void
      untyped __global__.__int64_hash_set_int(__cpp__("HX_MAP_THIS"), key, value);

   public function get(key:Int64):Int
      return untyped __global__.__int64_hash_get_int(h, key);

   public function exists(key:Int64):Bool
      return untyped __global__.__int64_hash_exists(h, key);

   public function remove(key:Int64):Bool
      return untyped __global__.__int64_hash_remove(h, key);

   public function count():Int
   {
      var keys:Array<Int64> = untyped __global__.__int64_hash_keys(h);
      return keys.length;
   }
}

class TestInt64Hash extends Test
{
   // Keys whose halves collided when they were xored: packed pairs, the same
   // pairs swapped, equal halves and negative halves
   function checkKeys(keys:Array<Int64>, ?pos:haxe.PosInfos)
   {
      var map = new Int64Table();
      for(i in 0...keys.length)
         map.set(keys[i], i);
      Assert.equals(keys.length, map.count(), pos);
      var ok = true;
      for(i in 0...keys.length)
         ok = ok && map.exists(keys[i]) && map.get(keys[i])==i;
      Assert.isTrue(ok, pos);
   }

   public function testPackedPairs()
   {
      checkKeys([for(x in 0...128) for(y in 0...128) Int64.make(x, y)]);
      checkKeys([for(x in 0...128) for(y in 0...128) Int64.make(y, x)]);
   }

   public function testEqualAndNegativeHalves()
   {
      checkKeys([for(i in 0...4096) Int64.make(i, i)]);
      checkKeys([for(i in 0...4096) Int64.make(-1 - (i & 63), -1 - (i >> 6))]);
   }

   public function testOneHalf()
   {
      checkKeys([for(i in 0...4096) Int64.make(i, 0)]);
      checkKeys([for(i in 0...4096) Int64.make(0, i)]);
   }

   public function testRemoveCollidingPair()
   {
      var map = new Int64Table();
      map.set(Int64.make(3, 5), 1);
      map.set(Int64.make(5, 3), 2);
      map.set(Int64.make(4, 4), 3);
      map.set(Int64.make(6, 6), 4);
      Assert.isTrue(map.remove(Int64.make(3, 5)));
      Assert.isFalse(map.exists(Int64.make(3, 5)));
      Assert.equals(2, map.get(Int64.make(5, 3)));
      Assert.isTrue(map.remove(Int64.make(4, 4)));
      Assert.isFalse(map.exists(Int64.make(4, 4)));
      Assert.equals(4, map.get(Int64.make(6, 6)));
      Assert.isFalse(map.exists(Int64.make(5, 5)));
   }
}
