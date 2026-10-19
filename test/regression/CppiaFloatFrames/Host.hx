class Host {
	public static var fromScript:Float->Float->Float;

	// Called from the script: its arguments and result cross the host glue
	public static function combine(a:Float, b:Float):Float
		return a * 3 + b;
}
