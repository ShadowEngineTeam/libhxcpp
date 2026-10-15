function main() {
	var s = "b";
	Sys.println((untyped __cpp__("::cpp::Variant({0}) <= HX_CSTRING(\"b\")", s) : Bool));
	Sys.println((untyped __cpp__("::cpp::Variant({0}) <= HX_CSTRING(\"a\")", s) : Bool));
	Sys.println((untyped __cpp__("::cpp::Variant({0}) >= HX_CSTRING(\"b\")", s) : Bool));
	Sys.println((untyped __cpp__("::cpp::Variant({0}) < HX_CSTRING(\"b\")", s) : Bool));
}
