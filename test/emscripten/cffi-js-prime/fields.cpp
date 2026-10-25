#include <map>
#include <vector>
#include <string>
#include <cstdio>
#define HXCPP_JS_PRIME
#define IMPLEMENT_API
#include <hx/CFFI.h>
int main() {
 const char *names[]={"plain","caf\xc3\xa9","\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e","emoji\xf0\x9f\x98\x80"};
 for(int i=0;i<4;i++) {
  int id=val_id(names[i]);
  value object=value::object();
  value key=value::u8string(names[i]);
  object.set(key,value(7));
  value found=val_field(object,id);
  bool read=!found.isUndefined() && found.as<int>()==7;
  alloc_field(object,id,alloc_int(9));
  bool write=object[key].as<int>()==9;
  int fields=value::global("Object").call<value>("keys",object)["length"].as<int>();
  printf("case %d read=%d write=%d fields=%d\n",i,read,write,fields);
 }
 return 0;
}