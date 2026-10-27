import utest.Test;
import utest.Assert;
import sys.thread.Deque;
import sys.thread.Thread;

// Deque.push leaves free slots in front of the items instead of moving them
// all for each push (libhxcpp #317)
class TestDeque extends Test
{
   static function drain(q:Deque<Dynamic>):Array<Int>
   {
      var out = [];
      while(true)
      {
         var v = q.pop(false);
         if (v==null)
            return out;
         out.push(v);
      }
   }

   function testFrontInsertionOrder()
   {
      var q = new Deque<Dynamic>();
      var n = 65536;
      for(i in 0...n)
         q.push(i);
      var out = drain(q);
      Assert.equals(n, out.length);
      var ok = true;
      for(i in 0...n)
         if (out[i]!=n-1-i)
            ok = false;
      Assert.isTrue(ok);
   }

   // The same operations on a deque and on an array model
   function testMixedOperations()
   {
      var q = new Deque<Dynamic>();
      var model:Array<Int> = [];
      var seed = 12345;
      var ok = true;
      for(step in 0...200000)
      {
         seed = (seed * 1103515245 + 12345) & 0x7fffffff;
         switch((seed >> 8) % 5)
         {
            case 0, 1:
               q.add(step);
               model.push(step);
            case 2, 3:
               q.push(step);
               model.unshift(step);
            default:
               if (q.pop(false)!=model.shift())
                  ok = false;
         }
         if (step % 50000 == 0)
            cpp.vm.Gc.run(true);
      }
      Assert.isTrue(ok);
      Assert.same(model, drain(q));
   }

   // A deep backlog popped until the consumed prefix is compacted, then
   // pushes at the front again
   function testFrontPushAfterCompaction()
   {
      var q = new Deque<Dynamic>();
      for(i in 0...10000)
         q.add(i);
      for(i in 0...6000)
         q.pop(false);
      for(i in 0...100)
         q.push(-1 - i);
      var expected = [for(i in 0...100) i - 100].concat([for(i in 6000...10000) i]);
      Assert.same(expected, drain(q));
   }

   function testPushedValuesSurviveCollection()
   {
      var q = new Deque<Dynamic>();
      for(i in 0...1000)
         q.push(Std.string(i));
      cpp.vm.Gc.run(true);
      cpp.vm.Gc.compact();
      var ok = true;
      for(i in 0...1000)
         if (q.pop(false)!=Std.string(999 - i))
            ok = false;
      Assert.isTrue(ok);
   }

   function testPushWakesBlockedConsumer()
   {
      var q = new Deque<Dynamic>();
      var main = Thread.current();
      Thread.create(() -> main.sendMessage(q.pop(true)));
      Sys.sleep(0.05);
      q.push(42);
      Assert.equals(42, Thread.readMessage(true));
   }
}
