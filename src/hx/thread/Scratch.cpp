#include <hxcpp.h>

#if (HXCPP_API_LEVEL>=500)
#include <hx/thread/Scratch.hpp>
#include "ThreadImpl.hpp"

namespace
{
	// The reference count, then the start of the pooled allocation below
	// this one, keeping the data 8-byte aligned
	constexpr int headerSize = 8;

	int padded(int bytes)
	{
		return (bytes + 7) & ~7;
	}
}

hx::thread::Scratch hx::thread::Scratch::alloc(int bytes)
{
	auto current = reinterpret_cast<hx::thread::ThreadImpl_obj*>(hx::thread::Thread_obj::current().GetPtr());
	auto required = headerSize + padded(bytes);

	// If there is not enough space in the thread array then do a standard malloc.
	// Maybe we want some warning log message so the user knows it's hitting a slower path?
	if (static_cast<uint64_t>(required) > static_cast<uint64_t>(current->scratch->length) - current->cursor)
	{
		auto alloc   = std::malloc(headerSize + bytes);
		auto storage = new(alloc) int;
		auto view    = cpp::marshal::View<uint8_t>(static_cast<uint8_t*>(alloc) + headerSize, bytes);

		std::memset(alloc, 0, headerSize + bytes);

		return
			hx::thread::Scratch(storage, view, [](cpp::marshal::View<uint8_t> view) {
				std::free(view.ptr.ptr - headerSize);
			});
	}
	else
	{
		auto base    = current->scratch->GetBase();
		auto start   = current->cursor;
		auto storage = new(base + start) int(0);
		auto view    = cpp::marshal::View<uint8_t>(reinterpret_cast<uint8_t*>(base) + start + headerSize, bytes);

		reinterpret_cast<int*>(base + start)[1] = current->scratchTop;
		current->scratchTop = start;
		current->cursor += required;

		return
			hx::thread::Scratch(storage, view, [](cpp::marshal::View<uint8_t> view) {
				view.fill(0);

				auto current = reinterpret_cast<hx::thread::ThreadImpl_obj*>(hx::thread::Thread_obj::current().GetPtr());
				auto base    = current->scratch->GetBase();

				// An allocation released while newer ones live is reclaimed
				// once everything above it has been released
				while (current->scratchTop >= 0)
				{
					auto header = reinterpret_cast<int*>(base + current->scratchTop);
					if (header[0] != 0)
						break;
					current->cursor = current->scratchTop;
					current->scratchTop = header[1];
				}
			});
	}
}

hx::thread::Scratch::Scratch(int* _count, cpp::marshal::View<uint8_t> _view, ReleaseFunc _release) : count(_count), view(_view), release(_release)
{
	(*count)++;
}

hx::thread::Scratch::Scratch(const Scratch& _other) : count(_other.count), view(_other.view), release(_other.release)
{
	(*count)++;
}

hx::thread::Scratch::~Scratch()
{
	if (0 == --(*count))
	{
		release(view);
	}
}

hx::thread::Scratch& hx::thread::Scratch::operator=(const Scratch& _other)
{
	(*_other.count)++;

	if (0 == --(*count))
	{
		release(view);
	}

	count = _other.count;
	view = _other.view;
	release = _other.release;

	return *this;
}

#endif
