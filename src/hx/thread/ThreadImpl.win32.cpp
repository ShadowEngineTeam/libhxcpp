#include <hxcpp.h>
#include <windows.h>
#include <memory>
#include <sstream>
#include <hx/thread/Thread.hpp>
#include "ThreadImpl.hpp"
#include <comdef.h>

String hx::thread::ThreadImpl_obj::getName()
{
	hx::EnterGCFreeZone();
	
	auto buffer = PWSTR{ nullptr };
	auto result = GetThreadDescription(native->handle, &buffer);
	if (FAILED(result))
	{
		_com_error error(result);
	
		auto msg = error.ErrorMessage();
	
		hx::ExitGCFreeZone();
		hx::Throw(String::create(msg));
	}
	
	hx::ExitGCFreeZone();
	
	auto converted = String::create(buffer);
	
	LocalFree(buffer);
	
	return converted;
}

void hx::thread::ThreadImpl_obj::setName(const String& name)
{
	hx::strbuf buffer;
	hx::EnterGCFreeZone();

	auto result = SetThreadDescription(native->handle, name.wchar_str(&buffer));
	if (FAILED(result))
	{
		_com_error error(result);
	
		auto msg = error.ErrorMessage();
	
		hx::ExitGCFreeZone();
		hx::Throw(String::create(msg));
	}
	else
	{
		hx::ExitGCFreeZone();
	}
}

// A real handle: GetCurrentThread's pseudo-handle names whichever thread uses it
hx::thread::ThreadImpl_obj::Native::Native()
	: thread()
	, handle(OpenThread(THREAD_QUERY_LIMITED_INFORMATION | THREAD_SET_LIMITED_INFORMATION, FALSE, GetCurrentThreadId()))
	, ownsHandle(handle != nullptr)
{
	if (!handle)
		handle = GetCurrentThread();
}

hx::thread::ThreadImpl_obj::Native::~Native()
{
	if (ownsHandle)
		CloseHandle(handle);
}
