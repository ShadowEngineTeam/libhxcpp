#include <hxcpp.h>
#include <windows.h>
#include <memory>
#include <hx/Thread.h>
#include <hx/thread/CountingSemaphore.hpp>

struct hx::thread::CountingSemaphore_obj::Impl
{
	HANDLE semaphore;

	static void finalise(hx::Object* obj)
	{
		auto impl = std::unique_ptr<Impl>(reinterpret_cast<hx::thread::CountingSemaphore_obj*>(obj)->impl);

		CloseHandle(impl->semaphore);
	}
};

hx::thread::CountingSemaphore_obj::CountingSemaphore_obj(int value) : impl(new Impl())
{
	if (nullptr == (impl->semaphore = CreateSemaphoreW(nullptr, value, 0x7FFFFFFF, nullptr)))
	{
		delete impl;
		impl = nullptr;
		hx::Throw(HX_CSTRING("Failed to create semaphore"));
	}

	hx::GCSetFinalizer(this, Impl::finalise);
}

void hx::thread::CountingSemaphore_obj::acquire()
{
	// Uncontended fast path - skip the GC free zone unless we will block
	if (NO_ERROR == WaitForSingleObject(impl->semaphore, 0))
		return;

	hx::EnterGCFreeZone();

	if (NO_ERROR != WaitForSingleObject(impl->semaphore, INFINITE))
	{
		hx::ExitGCFreeZone();
		hx::Throw(HX_CSTRING("Failed to wait for semaphore"));
	}

	hx::ExitGCFreeZone();
}

void hx::thread::CountingSemaphore_obj::release()
{
	if (false == ReleaseSemaphore(impl->semaphore, 1, nullptr))
	{
		hx::Throw(HX_CSTRING("Failed to release semaphore"));
	}
}

bool hx::thread::CountingSemaphore_obj::tryAcquire(Null<double> timeout)
{
	if (hx::gPauseForCollect)
		__hxcpp_gc_safe_point();
	// Zero-timeout poll cannot block - no free zone needed.  Also try a
	// non-blocking grab first for the timed case.
	DWORD waitMs = HxWaitMilliseconds(timeout.Default(0));
	switch (WaitForSingleObject(impl->semaphore, 0))
	{
	case NO_ERROR:
		return true;
	case WAIT_TIMEOUT:
		if (0 == waitMs)
			return false;
		break;
	default:
		return hx::Throw(HX_CSTRING("Failed to wait for semaphore"));
	}

	hx::EnterGCFreeZone();

	switch (WaitForSingleObject(impl->semaphore, waitMs))
	{
	case NO_ERROR:
		hx::ExitGCFreeZone();
		return true;
	case WAIT_TIMEOUT:
		hx::ExitGCFreeZone();
		return false;
	default:
		hx::ExitGCFreeZone();
		return hx::Throw(HX_CSTRING("Failed to wait for semaphore"));
	}
}