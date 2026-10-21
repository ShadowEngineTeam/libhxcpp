// A host that runs main again (wasm callMain, a plugin host) boots the program
// again: hx::Boot and __boot_all rerun every static initialiser, so the second
// run starts from the initial values. docs/ThreadsAndStacks.md relies on this.
@:cppFileCode('
static int sEntered = 0;
extern void __boot_all();
extern "C" void __hxcpp_main();
')
class Main {
	static var counter = 10;
	static var list = [1, 2, 3];

	static function main() {
		Sys.println("main: counter=" + counter + " list=" + list.length);
		counter++;
		list.push(4);
		var again:Bool = untyped __cpp__("sEntered++ == 0");
		if (again) {
			untyped __cpp__("::hx::Boot(); __boot_all(); __hxcpp_main();");
			Sys.println("after second main: counter=" + counter + " list=" + list.length);
		}
	}
}
