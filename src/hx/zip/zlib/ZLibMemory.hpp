#pragma once

#include <hxcpp.h>
#include <zlib-ng.h>

#include <atomic>
#include <cstdlib>

namespace hx
{
	namespace zip
	{
		namespace zlib
		{
			// The native memory a stream's zlib state holds, so the collector
			// can count it towards collection pressure
			struct ZLibMemory
			{
				std::atomic<size_t> live{ 0 };
				size_t reported = 0;

				static void * alloc(void * opaque, unsigned int items, unsigned int size)
				{
					size_t bytes = static_cast<size_t>(items) * size;
					// Two words before the data keep zlib's 16-byte alignment
					size_t *block = static_cast<size_t *>(std::malloc(bytes + sizeof(size_t) * 2));
					if (!block)
						return Z_NULL;
					block[0] = bytes;
					static_cast<ZLibMemory *>(opaque)->live += bytes;
					return block + 2;
				}

				static void free(void * opaque, void * address)
				{
					if (!address)
						return;
					size_t *block = static_cast<size_t *>(address) - 2;
					static_cast<ZLibMemory *>(opaque)->live -= block[0];
					std::free(block);
				}

				static ZLibMemory *attach(zng_stream *stream)
				{
					ZLibMemory *memory = new ZLibMemory();
					stream->zalloc = alloc;
					stream->zfree = free;
					stream->opaque = memory;
					return memory;
				}

				// Outside a GC-free zone only: growth can start a collection
				void report()
				{
					size_t now = live;
					if (now > reported)
						GCChangeManagedMemory(static_cast<int>(now - reported), "zlib");
					else if (now < reported)
						GCReleaseManagedMemory(reported - now);
					reported = now;
				}

				// Safe in a finalizer
				void release()
				{
					GCReleaseManagedMemory(reported);
					reported = 0;
				}
			};
		}
	}
}
