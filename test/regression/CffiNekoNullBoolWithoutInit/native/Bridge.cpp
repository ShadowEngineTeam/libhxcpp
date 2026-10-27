#define IMPLEMENT_API
// The glue for neko, which loads this ndll
#define NEKO_COMPATIBLE
#include <hx/CFFI.h>

value nc_null() { return alloc_null(); }
DEFINE_PRIM(nc_null,0);

value nc_true() { return alloc_bool(true); }
DEFINE_PRIM(nc_true,0);

value nc_false() { return alloc_bool(false); }
DEFINE_PRIM(nc_false,0);

// null, true and false as an object's fields, which neko takes as they are,
//  where it raises a primitive's C NULL result as an error
value nc_object()
{
   value result = alloc_empty_object();
   alloc_field(result,val_id("n"),alloc_null());
   alloc_field(result,val_id("t"),alloc_bool(true));
   alloc_field(result,val_id("f"),alloc_bool(false));
   return result;
}
DEFINE_PRIM(nc_object,0);

value nc_reads_true(value v) { return alloc_int(val_bool(v) ? 1 : 0); }
DEFINE_PRIM(nc_reads_true,1);
