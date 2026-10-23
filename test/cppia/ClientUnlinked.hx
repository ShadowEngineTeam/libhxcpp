// Uses classes and members the host does not have: the module must fail to
// link, naming each of them once.
extern class Unlinked
{
   public function new();
   public static function make():Unlinked;
   public static var count:Int;
}

// The host has HostBase, but not these members
@:native("HostBase")
extern class HostBaseExtra
{
   public function new();
   public function notInHost():Int;
   public var notInHostVar:Int;
   public static var notInHostStatic:Int;
}

class ClientUnlinked
{
   public static function main()
   {
      new Unlinked();
      Unlinked.make();
      trace(Unlinked.count);
      new Unlinked();
      trace(new HostBaseExtra().notInHost());
      trace(new HostBaseExtra().notInHostVar);
      new HostBaseExtra().notInHostVar = 2;
      Unlinked.count++;
      HostBaseExtra.notInHostStatic = 3;
      trace(HostBaseExtra.notInHostStatic);
   }
}
