// The two words before the data look like a large GC allocation
@:cppFileCode('
alignas(16) static unsigned int sBuf[4100];
static unsigned char *unmanagedData()
{
	sBuf[2] = 100000;
	sBuf[3] = 0x05000000;
	return (unsigned char *)(sBuf + 4);
}')
class Main {
	static function main() {
		var a:Array<cpp.UInt8> = [];
		cpp.NativeArray.setUnmanagedData(a, cpp.ConstPointer.fromRaw(untyped __cpp__("unmanagedData()")), 16000);
		cpp.NativeArray.setSize(a, 0);
		var intact:Bool = untyped __cpp__("sBuf[3] == 0x05000000");
		Sys.println(intact ? "unmanaged memory untouched" : "unmanaged memory released to the GC");
	}
}
