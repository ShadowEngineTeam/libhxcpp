class Host {
	// The size Main expects the calling thread's script stack to have
	public static var size:Int;
	// Script.check from each run of the script, interpreted and with the JIT
	public static var checks:Array<Int->Void> = [];
}
