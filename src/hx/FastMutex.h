#ifndef HX_FAST_MUTEX_H
#define HX_FAST_MUTEX_H

// A non-recursive mutex for the runtime's short, frequently taken critical
// sections (object ids, the large object list, field ids).
//
// On Windows, MSVC's std::mutex adds ownership bookkeeping around its lock:
// measured ~40ns per uncontended lock/unlock against ~3ns for the work it
// guards in GetObjectID, which made every ObjectMap operation slower than
// stock hxcpp's CRITICAL_SECTION (#232). A bare SRWLOCK has the same
// semantics as std::mutex here (exclusive, not recursive) without that cost.
// Elsewhere std::mutex is already a thin wrapper over the platform mutex.
//
// Satisfies BasicLockable, so std::lock_guard and std::unique_lock work.

#include <hx/Thread.h>
#include <mutex>

#if defined(HX_WINDOWS) && !defined(HXCPP_WINXP_COMPAT)

// Thread.h already includes it (after setting _WIN32_WINNT to Vista), but
// HX_THREAD_H_OVERRIDE can replace Thread.h with a header that does not.
#include <windows.h>

namespace hx
{
class FastMutex
{
public:
   FastMutex() { InitializeSRWLock(&mLock); }
   void lock() { AcquireSRWLockExclusive(&mLock); }
   void unlock() { ReleaseSRWLockExclusive(&mLock); }

private:
   FastMutex(const FastMutex &);
   FastMutex &operator=(const FastMutex &);

   SRWLOCK mLock;
};
}

#else

namespace hx
{
typedef std::mutex FastMutex;
}

#endif

#endif
