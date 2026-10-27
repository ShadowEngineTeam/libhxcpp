#ifndef HX_NEKO_FUNC_H
#define HX_NEKO_FUNC_H

#define NEKO_VERSION	180

typedef intptr_t int_val;

typedef enum {
	VAL_INT			= 0xFF,
	VAL_NULL		= 0,
	VAL_FLOAT		= 1,
	VAL_BOOL		= 2,
	VAL_STRING		= 3,
	VAL_OBJECT		= 4,
	VAL_ARRAY		= 5,
	VAL_FUNCTION	= 6,
	VAL_ABSTRACT	= 7,
	// neko 2: an Int beyond 31 bits, which neko 1.8 made an abstract
	VAL_INT32		= 8,
	VAL_PRIMITIVE	= 6 | 8,
	VAL_JITFUN		= 6 | 16,
	VAL_32_BITS		= 0xFFFFFFFF
} neko_val_type;

struct _neko_value {
	neko_val_type t;
};

struct _neko_objtable;
struct _neko_buffer;

#ifndef HAVE_NEKO_TYPES
typedef struct _neko_vkind *neko_vkind;
typedef struct _neko_value *neko_value;
typedef struct _neko_buffer *neko_buffer;
#endif

typedef struct _neko_objtable* neko_objtable;
typedef double tfloat;

typedef void (*finalizer)(neko_value v);

#pragma pack(4)
typedef struct {
	neko_val_type t;
	tfloat f;
} vfloat;

typedef struct {
	neko_val_type t;
	int i;
} vint32;
#pragma pack()

typedef struct _vobject {
	neko_val_type t;
	neko_objtable table;
	struct _vobject *proto;
} vobject;

typedef struct {
	neko_val_type t;
	int nargs;
	void *addr;
	neko_value env;
	void *module;
} vfunction;

typedef struct {
	neko_val_type t;
	char c;
} vstring;

typedef struct {
	neko_val_type t;
	neko_value ptr;
} varray;

typedef struct {
	neko_val_type t;
	neko_vkind kind;
	void *data;
} vabstract;


// A string's or array's length is kept in its tag, above 4 bits on neko 2 and
// above 3 on neko 1.8. The neko loader sets this for the neko it finds
static int neko_tag_bits = 4;

#define neko_val_tag(v)			(*(neko_val_type*)(v))
#define neko_val_short_tag(v)	(neko_val_tag(v) & ((1 << neko_tag_bits) - 1))
#define neko_val_is_null(v)		((v) == val_null)
#define neko_val_is_int(v)		((((int)(int_val)(v)) & 1) != 0)
#define neko_val_is_int32(v)		(!neko_val_is_int(v) && neko_val_tag(v) == VAL_INT32)
#define neko_val_is_number(v)	(neko_val_is_int(v) || neko_val_tag(v) == VAL_FLOAT || neko_val_tag(v) == VAL_INT32)
#define neko_val_is_float(v)		(!neko_val_is_int(v) && neko_val_tag(v) == VAL_FLOAT)
#define neko_val_is_string(v)	(!neko_val_is_int(v) && neko_val_short_tag(v) == VAL_STRING)
#define neko_val_is_function(v)	(!neko_val_is_int(v) && neko_val_short_tag(v) == VAL_FUNCTION)
#define neko_val_is_object(v)	(!neko_val_is_int(v) && neko_val_tag(v) == VAL_OBJECT)
#define neko_val_is_array(v)		(!neko_val_is_int(v) && neko_val_short_tag(v) == VAL_ARRAY)
#define neko_val_is_abstract(v)  (!neko_val_is_int(v) && neko_val_tag(v) == VAL_ABSTRACT)
#define neko_val_is_kind(v,t)	(neko_val_is_abstract(v) && neko_val_kind(v) == (t))
#define neko_val_check_kind(v,t)	if( !neko_val_is_kind(v,t) ) neko_error();
#define neko_val_check_function(f,n) if( !neko_val_is_function(f) || (neko_val_fun_nargs(f) != (n) && neko_val_fun_nargs(f) != VAR_ARGS) ) neko_error();
#define neko_val_check(v,t)		if( !neko_val_is_##t(v) ) neko_error();
#define neko_val_data(v)			((vabstract*)(v))->data
#define neko_val_kind(v)			((vabstract*)(v))->kind

#define neko_val_type(v)			(neko_val_is_int(v) ? VAL_INT : neko_val_short_tag(v))
#define neko_val_int(v)			(((int)(int_val)(v)) >> 1)
#define neko_val_int32(v)		(((vint32*)(v))->i)
#define neko_val_float(v)		(CONV_FLOAT ((vfloat*)(v))->f)
#define neko_val_bool(v)			((v) == neko_val_true)
#define neko_val_number(v)		(neko_val_is_int(v)?neko_val_int(v):neko_val_is_int32(v)?neko_val_int32(v):neko_val_float(v))
#define neko_val_hdata(v)		((vhash*)neko_val_data(v))
#define neko_val_string(v)		(&((vstring*)(v))->c)
#define neko_val_strlen(v)		((int)(((unsigned)neko_val_tag(v)) >> neko_tag_bits))
#define neko_val_set_length(v,l) neko_val_tag(v) = (neko_val_type)(neko_val_short_tag(v) | ((l) << neko_tag_bits))
#define neko_val_set_size		neko_val_set_length

#define neko_val_array_size(v)	((int)(((unsigned)neko_val_tag(v)) >> neko_tag_bits))
#define neko_val_array_ptr(v)	(&((varray*)(v))->ptr)
#define neko_val_fun_nargs(v)	((vfunction*)(v))->nargs
#define neko_alloc_int(v)		((neko_value)(int_val)((((int)(v)) << 1) | 1))
#define neko_alloc_bool(b)		((b)?neko_val_true:neko_val_false)
// Whether an Int is beyond the 31 bits neko_alloc_int holds
#define neko_need_32_bits(i)	((((unsigned int)(i)) + 0x40000000) & 0x80000000)

#define neko_max_array_size		((1 << (32 - neko_tag_bits)) - 1)
#define neko_max_string_size		((1 << (32 - neko_tag_bits)) - 1)
#define neko_invalid_comparison	0xFE

#endif // HX_NEKO_FUNC_H
