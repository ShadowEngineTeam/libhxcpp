import utest.Test;
import utest.Assert;

// Reflect on anonymous object literals of many widths, with names that are
// string literals and the same names built at run time, which are looked up
// differently: a literal by its address on a narrow object, by hash on a
// wide one. Every read, check, write and removal must agree.
class TestAnonFields extends Test
{
   static function runtime(name:String):String
   {
      var b = new StringBuf();
      for(i in 0...name.length)
         b.addChar(name.charCodeAt(i));
      return b.toString();
   }

   function check(width:Int, o:Dynamic, ?pos:haxe.PosInfos)
   {
      var literals = ["f0000", "f0003", "f0004", "f0005", "f0015", "f0016", "f0017", "f0063", "f0127", "f0255", "fjhnpacp", "fvqtonsi"];
      for(literal in literals)
      {
         var index = literal.charAt(1)=="0" ? Std.parseInt(literal.substr(1)) : -1;
         var expected:Null<Int> = index >= width ? null : index >= 0 ? index : literal=="fjhnpacp" ? -1 : -2;
         var name = runtime(literal);
         Assert.equals(expected, Reflect.field(o, literal), pos);
         Assert.equals(expected, Reflect.field(o, name), pos);
         Assert.equals(expected!=null, Reflect.hasField(o, literal), pos);
         Assert.equals(expected!=null, Reflect.hasField(o, name), pos);
      }
      Assert.isFalse(Reflect.hasField(o, "missing"), pos);
      Assert.isFalse(Reflect.hasField(o, runtime("missing")), pos);
      Assert.isNull(Reflect.field(o, "f9999"), pos);
      Assert.isTrue(Reflect.hasField(o, "nul"), pos);
      Assert.isNull(Reflect.field(o, runtime("nul")), pos);

      Reflect.setField(o, "fvqtonsi", 20);
      Reflect.setField(o, runtime("fjhnpacp"), 10);
      Assert.equals(20, Reflect.field(o, runtime("fvqtonsi")), pos);
      Assert.equals(10, Reflect.field(o, "fjhnpacp"), pos);
      Reflect.setField(o, "f0000", 100);
      Assert.equals(100, Reflect.field(o, runtime("f0000")), pos);
      Reflect.setField(o, "addedLater", 7);
      Reflect.setField(o, "ünïcode", 8);
      Assert.equals(7, Reflect.field(o, runtime("addedLater")), pos);
      Assert.equals(8, Reflect.field(o, "ünïcode"), pos);
      Assert.isTrue(Reflect.hasField(o, runtime("ünïcode")), pos);

      Reflect.deleteField(o, "fjhnpacp");
      Assert.isFalse(Reflect.hasField(o, runtime("fjhnpacp")), pos);
      Assert.equals(20, Reflect.field(o, "fvqtonsi"), pos);
      Reflect.deleteField(o, runtime("f0000"));
      Assert.isFalse(Reflect.hasField(o, "f0000"), pos);
      Assert.equals(20, Reflect.field(o, "fvqtonsi"), pos);
   }

   // The fixed field counts are the width plus three: either side of the
   // unrolled first five, and of the 40 fields up to which a literal name
   // is looked for by its address
   public function testNarrow()
   {
      check(1, AnonLiteral.wide(1));
      check(2, AnonLiteral.wide(2));
      check(4, AnonLiteral.wide(4));
      check(5, AnonLiteral.wide(5));
      check(13, AnonLiteral.wide(13));
      check(14, AnonLiteral.wide(14));
   }

   public function testWide()
   {
      check(37, AnonLiteral.wide(37));
      check(38, AnonLiteral.wide(38));
      check(64, AnonLiteral.wide(64));
      check(256, AnonLiteral.wide(256));
   }

   public function testNonAsciiLiteralNames()
   {
      var unicode = {"日本": 1, "é": 2, plain: 3};
      Assert.equals(1, Reflect.field(unicode, "日本"));
      Assert.equals(2, Reflect.field(unicode, runtime("é")));
      Assert.equals(3, unicode.plain);
   }
}
