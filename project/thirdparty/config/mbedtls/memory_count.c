/*
 * The allocator hxcpp builds mbedTLS with (MBEDTLS_PLATFORM_CALLOC_MACRO,
 * see include/mbedtls_config.h): calloc and free, which also count bytes for
 * a thread that asks. hxcpp's SSL counts a TLS context's native memory
 * towards collection pressure, and mbedTLS has a single allocator for the
 * whole process, with no hooks per context, so a context's memory is found
 * as what the calls on it allocate less what they free: while a thread has
 * a counter set, the blocks its mbedTLS calls allocate and free change it.
 * Each block keeps its size in front of it for the free. With no counter
 * set, as for every user of this mbedTLS that is not hxcpp's SSL, nothing
 * is counted.
 */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#if defined(_MSC_VER)
#define HXCPP_MBEDTLS_THREAD_LOCAL __declspec(thread)
#else
#define HXCPP_MBEDTLS_THREAD_LOCAL __thread
#endif

static HXCPP_MBEDTLS_THREAD_LOCAL ptrdiff_t *hxcpp_mbedtls_counter = NULL;

/* Two words before the data keep calloc's alignment */
#define HXCPP_MBEDTLS_HEADER (sizeof(size_t) * 2)

void *hxcpp_mbedtls_calloc(size_t n, size_t size)
{
	size_t bytes;
	size_t *block;
	if (n != 0 && size > (SIZE_MAX - HXCPP_MBEDTLS_HEADER) / n)
		return NULL;
	bytes = n * size;
	block = (size_t *)calloc(1, bytes + HXCPP_MBEDTLS_HEADER);
	if (block == NULL)
		return NULL;
	block[0] = bytes;
	if (hxcpp_mbedtls_counter)
		*hxcpp_mbedtls_counter += (ptrdiff_t)bytes;
	return block + 2;
}

void hxcpp_mbedtls_free(void *ptr)
{
	size_t *block;
	if (ptr == NULL)
		return;
	block = (size_t *)ptr - 2;
	if (hxcpp_mbedtls_counter)
		*hxcpp_mbedtls_counter -= (ptrdiff_t)block[0];
	free(block);
}

/* Sets the counter this thread's allocations and frees change from now on,
   or none, and returns the one set before. */
ptrdiff_t *hxcpp_mbedtls_count_into(ptrdiff_t *counter)
{
	ptrdiff_t *previous = hxcpp_mbedtls_counter;
	hxcpp_mbedtls_counter = counter;
	return previous;
}
