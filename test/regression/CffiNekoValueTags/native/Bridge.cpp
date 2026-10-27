#define IMPLEMENT_API
// The glue for neko, which loads this ndll
#define NEKO_COMPATIBLE
#include <hx/CFFI.h>
#include <stdio.h>
#include <stdlib.h>

value nt_strlen(value v) { return alloc_int(val_strlen(v)); }
DEFINE_PRIM(nt_strlen,1);

value nt_type(value v) { return alloc_int(val_type(v)); }
DEFINE_PRIM(nt_type,1);

// The characters val_string gives, as many as val_strlen says
value nt_copy(value v) { return alloc_string_len(val_string(v),val_strlen(v)); }
DEFINE_PRIM(nt_copy,1);

value nt_array_size(value v) { return alloc_int(val_array_size(v)); }
DEFINE_PRIM(nt_array_size,1);

value nt_array_sum(value v)
{
   int sum = 0;
   int n = val_array_size(v);
   for(int i=0;i<n;i++)
      sum += val_int(val_array_i(v,i));
   return alloc_int(sum);
}
DEFINE_PRIM(nt_array_sum,1);

// What val_int reads, as text, and an Int made from text, apart from each other
value nt_int_text(value v)
{
   char text[32];
   snprintf(text,sizeof(text),"%d",val_int(v));
   return alloc_string(text);
}
DEFINE_PRIM(nt_int_text,1);

value nt_int_parse(value v) { return alloc_int(atoi(val_string(v))); }
DEFINE_PRIM(nt_int_parse,1);

value nt_number(value v) { return alloc_float(val_number(v)); }
DEFINE_PRIM(nt_number,1);
