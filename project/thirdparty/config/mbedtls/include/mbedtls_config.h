#ifdef HX_WINDOWS
#define MBEDTLS_THREADING_ALT
#endif
#ifndef HX_WINDOWS
#define MBEDTLS_THREADING_PTHREAD
#endif

#define MBEDTLS_THREADING_C

// The allocator, in ../memory_count.c: calloc and free, which also count
// the memory a thread's mbedTLS calls hold, so hxcpp's SSL can report a TLS
// context's to the collector. As macros, there is no
// mbedtls_platform_set_calloc_free to put another allocator in its place
// under blocks it has already allocated.
#define MBEDTLS_PLATFORM_MEMORY
#define MBEDTLS_PLATFORM_CALLOC_MACRO hxcpp_mbedtls_calloc
#define MBEDTLS_PLATFORM_FREE_MACRO hxcpp_mbedtls_free
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
void *hxcpp_mbedtls_calloc(size_t n, size_t size);
void hxcpp_mbedtls_free(void *ptr);
#ifdef __cplusplus
}
#endif

#if defined(MBEDTLS_THREADING_ALT) && defined(_MSC_VER)
// Every object built against this configuration -- mbedTLS's own, hxcpp's
// SSL, a native extension, a static Lime's curl -- pulls into the link the
// initializer that installs the Windows mutexes before main
// (../../threading_alt.c), so they are in place for code that never calls
// hxcpp's _hx_ssl_init().
#if defined(_M_IX86)
#pragma comment(linker, "/include:_hxcpp_mbedtls_threading_initializer")
#else
#pragma comment(linker, "/include:hxcpp_mbedtls_threading_initializer")
#endif
#endif
