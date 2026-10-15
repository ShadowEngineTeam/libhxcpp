class ToolCore {
	public static var replaceable_func:Void->Void = nullAction;

	public static function nullAction():Void {
		Sys.println("not replaced");
	}
}
