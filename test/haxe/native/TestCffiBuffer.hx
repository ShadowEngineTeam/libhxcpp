package native;

import haxe.io.Bytes;
import haxe.io.BytesData;
import utest.Test;
import utest.Assert;

// The CFFI buffer functions append chunks with the growth push gets instead
// of to the exact length. The contents, NULs included, and the length must
// be as before, through every append function and after the array shrinks.
@:cppFileCode('
// The runtime is linked in, so call its CFFI functions directly
#define STATIC_LINK
#include <hx/CFFI.h>

static Dynamic test_cffi_chunks(int inChunk, int inCount)
{
   char chunk[4096];
   buffer b = alloc_buffer_len(0);
   for(int c=0;c<inCount;c++)
   {
      for(int i=0;i<inChunk;i++)
         chunk[i] = (char)((c*31 + i*7) & 0xff);
      buffer_append_sub(b, chunk, inChunk);
   }
   return Dynamic((hx::Object *)buffer_val(b));
}

static Dynamic test_cffi_mixed()
{
   const char withNul[] = { 97, 0, 98 }; // a, NUL, b
   buffer b = alloc_buffer("start");
   buffer_append(b, "");
   buffer_append_sub(b, "x", 0);
   buffer_append_sub(b, withNul, 3);
   buffer_append_char(b, 0);
   buffer_append(b, "-text-");
   buffer_append_char(b, 0x7e);
   return Dynamic((hx::Object *)buffer_val(b));
}

static void test_cffi_append(Dynamic inArray, int inCount)
{
   buffer b = val_to_buffer((value)inArray.mPtr);
   for(int i=0;i<inCount;i++)
      buffer_append_sub(b, "0123456789", 10);
}
')
class TestCffiBuffer extends Test
{
   static function expectedChunks(chunk:Int, count:Int):Bytes
   {
      var b = Bytes.alloc(chunk * count);
      for(c in 0...count)
         for(i in 0...chunk)
            b.set(c * chunk + i, (c * 31 + i * 7) & 0xff);
      return b;
   }

   public function testChunks()
   {
      for(size in [[1, 1], [17, 3], [1024, 1024], [4096, 300], [1000, 1025], [0, 5]])
      {
         var data:BytesData = untyped __cpp__("test_cffi_chunks({0}, {1})", size[0], size[1]);
         var bytes = Bytes.ofData(data);
         Assert.equals(size[0] * size[1], bytes.length);
         Assert.equals(0, bytes.compare(expectedChunks(size[0], size[1])));
      }
   }

   public function testMixedAppends()
   {
      var mixed = Bytes.ofData(untyped __cpp__("test_cffi_mixed()"));
      var expected = Bytes.ofString("starta\x00b\x00-text-~");
      Assert.equals(expected.length, mixed.length);
      Assert.equals(0, mixed.compare(expected));
   }

   public function testAppendAfterShrinking()
   {
      var data:BytesData = untyped __cpp__("test_cffi_chunks(1000, 100)");
      data.resize(10);
      untyped __cpp__("test_cffi_append({0}, 3)", data);
      var after = Bytes.ofData(data);
      Assert.equals(40, after.length);
      var prefix = true;
      for(i in 0...10)
         prefix = prefix && after.get(i)==((i * 7) & 0xff);
      Assert.isTrue(prefix);
      Assert.equals("012345678901234567890123456789", after.getString(10, 30));
   }
}
