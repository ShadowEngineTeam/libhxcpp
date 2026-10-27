#define IMPLEMENT_API
#include <hx/CFFI.h>
// The library has this primitive and not the quietMissing the test also asks for
value quietPresent(value inValue) { return inValue; }
DEFINE_PRIM(quietPresent,1);
