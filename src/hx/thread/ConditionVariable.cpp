#include <hxcpp.h>
#include "hx/thread/ConditionVariable.hpp"
#include <mutex>
#include <condition_variable>
#include <chrono>

struct hx::thread::ConditionVariable_obj::Impl
{
	std::mutex mutex;
	std::condition_variable_any condition;
};

hx::thread::ConditionVariable_obj::ConditionVariable_obj() : impl(new Impl())
{
	GCSetFinalizer(this, [](hx::Object* obj)
	{
		auto condition = reinterpret_cast<ConditionVariable_obj*>(obj);

		delete condition->impl;
	});
}

void hx::thread::ConditionVariable_obj::acquire()
{
	// Uncontended fast path - skip the GC free zone unless we will block
	// The free zone below was this thread's handshake with the collector. A
	// thread that only ever takes the lock uncontended, allocating nothing,
	// otherwise never reaches a safe point, and a collection waits for it
	// for ever.
	if (hx::gPauseForCollect)
		__hxcpp_gc_safe_point();
	if (impl->mutex.try_lock())
		return;

	hx::AutoGCFreeZone zone;

	impl->mutex.lock();
}

bool hx::thread::ConditionVariable_obj::tryAcquire()
{
	if (hx::gPauseForCollect)
		__hxcpp_gc_safe_point();
	return impl->mutex.try_lock();
}

void hx::thread::ConditionVariable_obj::release()
{
	impl->mutex.unlock();
}

void hx::thread::ConditionVariable_obj::wait()
{
	hx::AutoGCFreeZone zone;

	impl->condition.wait(impl->mutex);
}

bool hx::thread::ConditionVariable_obj::timedWait(double seconds)
{
	// Upper bound for the timeout, about 31 years. Larger values would overflow
	// the integer nanosecond count of the clock once added to the current time.
	constexpr double maxSeconds = 1e9;

	// `!(seconds > 0)` also catches NaN.
	if (!(seconds > 0))
	{
		seconds = 0;
	}
	else if (seconds > maxSeconds)
	{
		seconds = maxSeconds;
	}

	auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::duration<double>(seconds));

	hx::AutoGCFreeZone zone;

	return impl->condition.wait_for(impl->mutex, duration) == std::cv_status::no_timeout;
}

void hx::thread::ConditionVariable_obj::signal()
{
	impl->condition.notify_one();
}

void hx::thread::ConditionVariable_obj::broadcast()
{
	impl->condition.notify_all();
}
