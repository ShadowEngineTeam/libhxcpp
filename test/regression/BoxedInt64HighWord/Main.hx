class Main {
	static function check(low:Int,high:Int):Bool {
		var boxed:Dynamic=haxe.Int64.make(1,low);
		Reflect.setField(boxed,"hi",high);
		var actual:haxe.Int64=cast boxed;
		return actual==haxe.Int64.make(high,low) && Reflect.field(boxed,"lo")==low && Reflect.field(boxed,"hi")==high;
	}
	static function main() {
		Sys.println("low top bit clear: "+check(0x7fffffff,2));
		Sys.println("low top bit set: "+check(0x80000000,2));
		Sys.println("all low bits set: "+check(-1,2));
		Sys.println("negative high word: "+check(-1,-3));
	}
}