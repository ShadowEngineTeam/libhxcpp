#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class AnonLiteral
{
   /**
      An object literal with fields f0000... holding their index, plus the
      two names fjhnpacp and fvqtonsi, which have the same string hash, and
      nul holding null.
   **/
   public static macro function wide(count:Int):Expr
   {
      var fields:Array<ObjectField> = [for(i in 0...count) {field: "f" + StringTools.lpad(Std.string(i), "0", 4), expr: macro $v{i}}];
      fields.push({field: "fjhnpacp", expr: macro -1});
      fields.push({field: "fvqtonsi", expr: macro -2});
      fields.push({field: "nul", expr: macro null});
      return {expr: EObjectDecl(fields), pos: Context.currentPos()};
   }
}
