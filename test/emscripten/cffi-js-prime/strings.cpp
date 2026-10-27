#include <map>
#include <vector>
#include <string>
#include <cstdio>
#include <cstring>
#define HXCPP_JS_PRIME
#define IMPLEMENT_API
#include <hx/CFFI.h>

// The ordinary CFFI echo, which failed to link: val_string and
// alloc_string_len had no JS Prime definitions (libhxcpp #346)
static value echo(value text) {
 return alloc_string(val_string(text));
}
DEFINE_PRIM(echo, 1);

static value echo_len(value text) {
 return alloc_string_len(val_string(text), val_strlen(text));
}
DEFINE_PRIM(echo_len, 1);

static value echo_wide(value text) {
 const wchar_t *w = val_wstring(text);
 return alloc_wstring_len(w, (int)wcslen(w));
}
DEFINE_PRIM(echo_wide, 1);

// Keeps its own string while a callback runs another primitive, which frees
// only what it was given
static value nested(value text, value callback) {
 const char *mine = val_string(text);
 std::string before(mine);
 callback(text);
 return alloc_bool(before == mine);
}
DEFINE_PRIM(nested, 2);

static value echo_mult(value *args, int count) {
 std::string joined;
 for (int i = 0; i < count; i++)
  joined += val_string(args[i]);
 return alloc_string(joined.c_str());
}
DEFINE_PRIM_MULT(echo_mult);

int main() {
 const char *texts[]={"plain","caf\xc3\xa9","\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e","emoji\xf0\x9f\x98\x80"};
 for (int i = 0; i < 4; i++) {
  value text = value::u8string(texts[i]);
  int mark = hx_js_prime_strings_mark();
  bool echoed = value::module_property("echo")(text).strictlyEquals(text);
  bool freed = hx_js_prime_strings_mark() == mark;
  bool withLength = value::module_property("echo_len")(text).strictlyEquals(text);
  bool wide = value::module_property("echo_wide")(text).strictlyEquals(text);
  bool length = val_strlen(text) == (int)strlen(texts[i]);
  printf("case %d echo=%d freed=%d len=%d wide=%d strlen=%d\n", i, echoed, freed, withLength, wide, length);
 }

 value inner = value::module_property("echo");
 bool kept = value::module_property("nested")(value::u8string(texts[3]), inner).as<bool>();
 printf("nested kept=%d\n", kept);

 // DEFINE_PRIM_MULT takes its arguments as one array
 value args = value::array();
 args.call<void>("push", value::u8string(texts[1]), value::u8string(texts[2]));
 value joined = value::module_property("echo_mult")(args);
 printf("mult=%d\n", joined.strictlyEquals(value::u8string((std::string(texts[1]) + texts[2]).c_str())));

 printf("null=\"%s\" number=\"%s\"\n", val_string(value::null()), val_string(value(42)));
 printf("prefix=%d\n", alloc_string_len(texts[1], 3).strictlyEquals(value::u8string("caf")));
 return 0;
}
