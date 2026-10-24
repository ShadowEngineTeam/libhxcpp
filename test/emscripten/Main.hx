// Runs past the limits Emscripten links with when hxcpp passes nothing: 16 MB
// of memory that cannot grow, and a 64 KB stack. Without ASSERTIONS a stack
// overflow is not caught: it writes over whatever lies below the stack.
@:cppFileCode('#include <emscripten/stack.h>')
class Main
{
   static inline var CHUNKS = 64;
   // Each frame takes about 64 bytes of Emscripten's stack, so this needs
   // about 128 KB, and stays below node's own limit on wasm frames
   static inline var DEPTH = 2000;

   static var deepestInStack = false;
   static var kept = 0;

   static function inStack():Bool
   {
      return untyped __cpp__("emscripten_stack_get_current() >= emscripten_stack_get_end()");
   }

   // A String in every frame, used after the call so the recursion stays a
   // recursion; the collection at the bottom has to find them all
   static function recurse(n:Int):Int
   {
      var held = "frame" + n;
      if (n == 0)
      {
         deepestInStack = inStack();
         cpp.vm.Gc.run(true);
         // Reuse whatever the collection freed
         var junk = [];
         for (i in 0...10000)
            junk.push("junk" + i);
         return junk.length;
      }
      var below = recurse(n - 1);
      if (held == "frame" + n)
         kept++;
      return below + held.length;
   }

   static function main()
   {
      var chunks = [];
      for (i in 0...CHUNKS)
      {
         var b = haxe.io.Bytes.alloc(1024 * 1024);
         b.fill(0, b.length, i);
         chunks.push(b);
      }
      cpp.vm.Gc.run(true);
      var intact = 0;
      for (i in 0...CHUNKS)
         if (chunks[i].get(0) == i && chunks[i].get(chunks[i].length - 1) == i)
            intact++;
      Sys.println('$intact of $CHUNKS MB intact');

      recurse(DEPTH);
      Sys.println('deepest frame inside the stack: $deepestInStack');
      Sys.println('$kept of $DEPTH frames kept their strings');
   }
}
