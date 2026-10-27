// Exceptions thrown through recursive calls, with collections between the
// throw and the catch: what is held by the caught value, and by the callers'
// locals, has to survive them. run.sh builds it with native wasm exceptions,
// the default, and with HXCPP_NO_WASM_EXEPTIONS, Emscripten's JavaScript
// exceptions (libhxcpp #337)
class Payload
{
   public var text:String;
   public var bytes:haxe.io.Bytes;
   public var depth:Int;

   public function new(depth:Int)
   {
      this.depth = depth;
      text = "payload é日本\u{1F600} " + depth;
      bytes = haxe.io.Bytes.alloc(4096);
      bytes.fill(0, bytes.length, depth & 0xff);
   }

   public function intact(depth:Int)
   {
      return this.depth == depth && text == "payload é日本\u{1F600} " + depth
         && bytes.get(0) == (depth & 0xff) && bytes.get(bytes.length - 1) == (depth & 0xff);
   }
}

class Main
{
   static inline var ROUNDS = 20;
   static inline var DEPTH = 200;

   static var localsKept = 0;

   static function churn()
   {
      var junk = [];
      for (i in 0...2000)
         junk.push("junk " + i + " é");
      return junk.length;
   }

   static function descend(n:Int, round:Int):Int
   {
      var local = "local " + n + " 日";
      if (n == 0)
      {
         cpp.vm.Gc.run(true);
         churn();
         throw new Payload(round);
      }
      try
      {
         return descend(n - 1, round) + 1;
      }
      catch (p:Payload)
      {
         // Every caller catches, collects and throws on, so its local has
         // to have survived the collections below it
         if (local == "local " + n + " 日")
            localsKept++;
         if (n % 50 == 0)
            cpp.vm.Gc.run(true);
         throw p;
      }
   }

   static function main()
   {
      var payloadsIntact = 0;
      for (round in 0...ROUNDS)
      {
         try
         {
            descend(DEPTH, round);
         }
         catch (p:Payload)
         {
            churn();
            cpp.vm.Gc.run(true);
            if (p.intact(round))
               payloadsIntact++;
         }
      }
      Sys.println('$payloadsIntact of $ROUNDS payloads intact');
      Sys.println('${localsKept} of ${ROUNDS * DEPTH} caller locals kept');

      var dynamicCaught = try { throw "plain \u{1F600}"; } catch (e:Dynamic) Std.string(e);
      Sys.println('string caught: ${dynamicCaught == "plain \u{1F600}"}');

      var finallyRan = false;
      try
      {
         try
            throw 1
         catch (e:String)
            Sys.println("wrong catch");
      }
      catch (e:Int)
      {
         finallyRan = e == 1;
      }
      Sys.println('outer catch took the Int: $finallyRan');
   }
}
