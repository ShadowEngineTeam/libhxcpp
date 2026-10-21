// Sys exists only on the sys targets; JS runs under node without hxnodejs
class Out {
	public static function println(s:String) {
		#if sys
		Sys.println(s);
		#elseif js
		js.Syntax.code("console.log({0})", s);
		#end
	}
}
