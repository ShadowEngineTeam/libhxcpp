import sys.thread.Lock;
import sys.thread.Thread;
import utest.Assert;
import utest.Test;

class TestAllocations extends Test
{
  // Keeps what the worker thread allocates reachable, so it is never
  // reclaimed after that thread's telemetry has been deleted
  static var tracked:Array<Dynamic> = [];

  // HXTAllocation skips allocations made inside a CFFI call. Skipping one
  // must leave alloc_mutex usable, or the next thread to lock it blocks.
  function testExternAllocationLeavesAllocationLockUsable()
  {
    var allocated = new Lock();
    Thread.create(function() {
      untyped __global__.__hxcpp_hxt_start_telemetry(true, true);
      tracked.push(allocateInExternFrame());
      tracked.push([4, 5, 6]);
      allocated.release();
    });
    Assert.isTrue(allocated.wait(10.0));

    // Stashing locks alloc_mutex, even without allocation tracking
    var stashed = new Lock();
    Thread.create(function() {
      untyped __global__.__hxcpp_hxt_stash_telemetry();
      stashed.release();
    });
    Assert.isTrue(stashed.wait(10.0));
  }

  // Restarting telemetry deletes the Telemetry that recorded these objects,
  // which collecting them must not reach
  function testCollectAfterRestart()
  {
    untyped __global__.__hxcpp_hxt_start_telemetry(true, true);
    var garbage = [for (i in 0...1000) [i]];
    garbage = null;
    untyped __global__.__hxcpp_hxt_start_telemetry(true, true);
    for (_ in 0...3)
      cpp.vm.Gc.run(true);
    Assert.pass();
  }

  // An exiting thread can delete its Telemetry, with what it recorded still
  // to be collected
  function testCollectAfterThreadsExit()
  {
    var done = new Lock();
    for (t in 0...6)
      Thread.create(function() {
        untyped __global__.__hxcpp_hxt_start_telemetry(true, true);
        var garbage = [for (i in 0...1000) [i, t]];
        garbage = null;
        done.release();
      });
    for (t in 0...6)
      Assert.isTrue(done.wait(10.0));
    Sys.sleep(0.5);
    for (_ in 0...3)
      cpp.vm.Gc.run(true);
    Assert.pass();
  }

  // Primitives loaded with cpp.Lib.load run inside a frame like this one
  // (see ExternalPrimitive in src/hx/Lib.cpp), so what they allocate takes
  // the extern path in HXTAllocation
  static function allocateInExternFrame():Array<Int>
  {
    var result:Array<Int> = null;
    untyped __cpp__('{
      HX_STACK_FRAME(::hx::EXTERN_CLASS_NAME, "cffi", 0, "extern::cffi", __FILE__, __LINE__, 0)
      {0} = ::Array_obj< int >::__new(3, 3);
    }', result);
    return result;
  }
}
