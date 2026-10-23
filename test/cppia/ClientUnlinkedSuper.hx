// Extends a class the host does not have: nothing in the class can be laid
// out, so the module fails to link at once, naming the class.
extern class UnlinkedBase
{
   public function new();
}

class UnlinkedChild extends UnlinkedBase
{
   public function new()
   {
      super();
   }
}

class ClientUnlinkedSuper
{
   public static function main()
   {
      new UnlinkedChild();
   }
}
