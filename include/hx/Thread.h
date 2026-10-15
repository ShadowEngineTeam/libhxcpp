#ifdef HX_THREAD_H_OVERRIDE
// Users can define their own header to use here, but there is no API
// compatibility gaurantee for future changes.
#include HX_THREAD_H_OVERRIDE
#else

#ifndef HX_THREAD_H
#define HX_THREAD_H

#ifndef HXCPP_HEADER_VERSION
#include "hx/HeaderVersion.h"
#endif

#ifdef HX_WINRT

#include <windows.h>
#include <process.h>
#include <mutex>

#elif defined(_WIN32)

#ifdef HXCPP_WINXP_COMPAT
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0400
#else
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0600
#endif

#include <windows.h>
#include <process.h>
#else
#include <errno.h>
#include <pthread.h>
#include <sys/time.h>
#include <time.h>
#include <stdio.h>
#ifdef __APPLE__
#include <mach/mach_time.h>
#endif
#define HXCPP_PTHREADS
#endif

#include <cmath>
#include <limits>

#ifdef RegisterClass
#undef RegisterClass
#endif

#if defined(HX_WINDOWS)

inline DWORD HxWaitMilliseconds(double inSeconds)
{
   if (!(inSeconds > 0))
      return 0;
   // double->DWORD is undefined past 2^32 (and 0xffffffff is INFINITE)
   double ms = std::ceil(inSeconds*1000.0);
   return ms >= 4294967294.0 ? 4294967294u : (DWORD)ms;
}

struct HxMutex
{
   HxMutex()
   {
      mValid = true;
      #ifdef HX_WINRT
      InitializeCriticalSectionEx(&mCritSec,4000,0);
      #else
      InitializeCriticalSection(&mCritSec);
      #endif
   }
   ~HxMutex() { if (mValid) DeleteCriticalSection(&mCritSec); }
   void Lock() { EnterCriticalSection(&mCritSec); }
   void Unlock() { LeaveCriticalSection(&mCritSec); }
   bool TryLock() { return TryEnterCriticalSection(&mCritSec); }
   bool IsValid() { return mValid; }
   void Clean()
   {
      if (mValid)
      {
         DeleteCriticalSection(&mCritSec);
         mValid = false;
      }
   }

   bool             mValid;
   CRITICAL_SECTION mCritSec;
};


#define THREAD_FUNC_TYPE DWORD WINAPI
#define THREAD_FUNC_RET return 0;

inline bool HxCreateDetachedThread(DWORD (WINAPI *func)(void *), void *param)
{
	// Close the handle immediately (the Windows detach idiom) - keeping it
	// leaked one kernel thread object per Thread.create for the process
	// lifetime
	HANDLE h = CreateThread(NULL, 0, func, param, 0, 0);
	if (!h)
		return false;
	CloseHandle(h);
	return true;
}

#else

struct HxMutex
{
   bool mValid;
   pthread_mutex_t *mMutex;

   HxMutex()
   {
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      mMutex = new pthread_mutex_t();
      mValid = pthread_mutex_init(mMutex,&mta) ==0;
   }
   ~HxMutex()
   {
      Clean();
   }
   void Lock() { pthread_mutex_lock(mMutex); }
   void Unlock() { pthread_mutex_unlock(mMutex); }
   bool TryLock() { return !pthread_mutex_trylock(mMutex); }
   bool IsValid() { return mValid; }
   void Clean()
   {
      if (mValid)
      {
         pthread_mutex_destroy(mMutex);
         mValid = false;
      }
      if (mMutex)
      {
         delete mMutex;
         mMutex = nullptr;
      }
   }
};

#define THREAD_FUNC_TYPE void *
#define THREAD_FUNC_RET return 0;

inline bool HxCreateDetachedThread(void *(*func)(void *), void *param)
{
	pthread_t t;
	pthread_attr_t attr;
	if (pthread_attr_init(&attr) != 0)
		return false;
#ifdef PTHREAD_CREATE_DETACHED
	if (pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0)
	{
		pthread_attr_destroy(&attr);
		return false;
	}
#endif
	bool ok = pthread_create(&t, &attr, func, param) == 0;
	// Destroy unconditionally and ignore the result: reporting failure
	// after a successful create would make the caller tear down state
	// the already-running thread is using
	pthread_attr_destroy(&attr);
	return ok;
}

#endif




template<typename LOCKABLE>
struct TAutoLock
{
   TAutoLock(LOCKABLE &inMutex) : mMutex(inMutex) { mMutex.Lock(); }
   ~TAutoLock() { mMutex.Unlock(); }
   void Lock() { mMutex.Lock(); }
   void Unlock() { mMutex.Unlock(); }

   LOCKABLE &mMutex;
};

typedef TAutoLock<HxMutex> AutoLock;


#if defined(HX_WINDOWS)

struct HxSemaphore
{
   HxSemaphore()
   {
      #ifdef HX_WINRT
      mSemaphore = CreateEventEx(nullptr,nullptr,0,EVENT_ALL_ACCESS);
      #else
      mSemaphore = CreateEvent(0,0,0,0);
      #endif
   }
   ~HxSemaphore() { if (mSemaphore) CloseHandle(mSemaphore); }
   void Set() { SetEvent(mSemaphore); }
   void Wait()
   {
      #ifdef HX_WINRT
      WaitForSingleObjectEx(mSemaphore,INFINITE,false);
      #else
      WaitForSingleObject(mSemaphore,INFINITE);
      #endif
   }
    // Returns true on success, false on timeout
   bool WaitSeconds(double inSeconds)
   {
      DWORD waitMs = HxWaitMilliseconds(inSeconds);
      #ifdef HX_WINRT
      return WaitForSingleObjectEx(mSemaphore,waitMs,false) != WAIT_TIMEOUT;
      #else
      return WaitForSingleObject(mSemaphore,waitMs) != WAIT_TIMEOUT;
      #endif
   }
   void Reset() { ResetEvent(mSemaphore); }
   void Clean() { if (mSemaphore) CloseHandle(mSemaphore); mSemaphore = 0; }

   HANDLE mSemaphore;
};

#else


#define HX_THREAD_SEMAPHORE_LOCKABLE

// Timed waits run on a clock that changing the system time does not move.
// Apple has no condition clock, so it waits for the time left instead.
#if !defined(__APPLE__) && (!defined(__ANDROID__) || __ANDROID_API__ >= 21)
#define HX_THREAD_COND_MONOTONIC
#endif

inline void HxAddSeconds(timespec &ioTime, double inSeconds)
{
   if (!(inSeconds > 0))
      return;
   time_t sec = 0x7ffffffe;
   long nsec = 0;
   if (inSeconds < sec)
   {
      double whole = std::floor(inSeconds);
      sec = (time_t)whole;
      nsec = (long)std::ceil((inSeconds - whole)*1000000000.0);
   }
   ioTime.tv_nsec += nsec;
   if (ioTime.tv_nsec >= 1000000000)
   {
      ioTime.tv_nsec -= 1000000000;
      sec++;
   }
   if (sec > std::numeric_limits<time_t>::max() - ioTime.tv_sec)
   {
      ioTime.tv_sec = std::numeric_limits<time_t>::max();
      ioTime.tv_nsec = 999999999;
   }
   else
      ioTime.tv_sec += sec;
}

struct HxSemaphore
{
   HxMutex         mMutex;
   pthread_cond_t  *mCondition;
   bool            mSet;


   HxSemaphore()
   {
      mSet = false;
      mCondition = new pthread_cond_t();
      #ifdef HX_THREAD_COND_MONOTONIC
      pthread_condattr_t attr;
      pthread_condattr_init(&attr);
      pthread_condattr_setclock(&attr, CLOCK_MONOTONIC);
      pthread_cond_init(mCondition,&attr);
      pthread_condattr_destroy(&attr);
      #else
      pthread_cond_init(mCondition,0);
      #endif
   }
   ~HxSemaphore()
   {
      Clean();
   }
   // For autolock
   inline operator HxMutex &() { return mMutex; }
   void Set()
   {
      AutoLock lock(mMutex);
      if (!mSet)
      {
         mSet = true;
         pthread_cond_signal( mCondition );
      }
   }
   void QSet()
   {
      mSet = true;
      pthread_cond_signal( mCondition );
   }
   void Reset()
   {
      AutoLock lock(mMutex);
      mSet = false;
   }
   void QReset() { mSet = false; }
   void Wait()
   {
      AutoLock lock(mMutex);
      while( !mSet )
         pthread_cond_wait( mCondition, mMutex.mMutex );
      mSet = false;
   }
   // when we already hold the mMutex lock ...
   void QWait()
   {
      while( !mSet )
         pthread_cond_wait( mCondition, mMutex.mMutex );
      mSet = false;
   }
   static void Now(timespec &outNow)
   {
      #ifdef __APPLE__
      static mach_timebase_info_data_t timebase;
      if (!timebase.denom)
         mach_timebase_info(&timebase);
      unsigned long long ns = mach_absolute_time() * timebase.numer / timebase.denom;
      outNow.tv_sec = ns / 1000000000;
      outNow.tv_nsec = ns % 1000000000;
      #elif defined(HX_THREAD_COND_MONOTONIC)
      clock_gettime(CLOCK_MONOTONIC, &outNow);
      #else
      clock_gettime(CLOCK_REALTIME, &outNow);
      #endif
   }
   int TimedWait(const timespec &inDeadline)
   {
      #ifdef __APPLE__
      timespec now;
      Now(now);
      timespec left;
      left.tv_sec = inDeadline.tv_sec - now.tv_sec;
      left.tv_nsec = inDeadline.tv_nsec - now.tv_nsec;
      if (left.tv_nsec<0)
      {
         left.tv_nsec += 1000000000;
         left.tv_sec--;
      }
      if (left.tv_sec<0)
         return ETIMEDOUT;
      return pthread_cond_timedwait_relative_np( mCondition, mMutex.mMutex, &left );
      #else
      return pthread_cond_timedwait( mCondition, mMutex.mMutex, &inDeadline );
      #endif
   }
   // Returns true if the wait was success, false on timeout.
   bool WaitSeconds(double inSeconds)
   {
      timespec spec;
      Now(spec);
      HxAddSeconds(spec, inSeconds);

      AutoLock lock(mMutex);

      int result = 0;
      // Wait for set to be true...
      while( !mSet &&  (result=TimedWait(spec)) != ETIMEDOUT)
      {
         if (result!=0)
         {
            // Error - something's gone wrong...
            /*
            if (result==EINVAL) 
               printf("ERROR: Condition EINVAL\n");
            else if (result==EPERM)
               printf("ERROR: Condition EPERM\n");
            else
               printf("ERROR: Condition unknown error\n");
            */
            break;
         }
         // Condition signalled - but try mSet again ...
      }

      bool wasSet = mSet;
      mSet = false;
      return wasSet;
   }
   void Clean()
   {
      mMutex.Clean();
      if (mCondition)
      {
         pthread_cond_destroy(mCondition);
         delete mCondition;
         mCondition = nullptr;
      }
   }

};


#endif


#if defined HX_WINRT

inline void HxSleep(unsigned int ms)
{
	::Sleep(ms);
}

#elif defined HX_WINDOWS

inline void HxSleep(unsigned int ms)
{
	::Sleep(ms);
}

#else

inline void HxSleep(unsigned int ms)
{
   struct timespec t;
   struct timespec tmp;
   t.tv_sec = 0;
   t.tv_nsec = ms * 1000000;
   nanosleep(&t, &tmp);
}

#endif


#endif
#endif
