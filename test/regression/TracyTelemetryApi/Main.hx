class Main {
	static function main() {
		untyped __global__.__hxcpp_hxt_start_telemetry(true, true);
		var frame:cpp.RawPointer<cpp.Void> = untyped __global__.__hxcpp_hxt_dump_telemetry(0);
		Sys.println(frame == null);
	}
}
