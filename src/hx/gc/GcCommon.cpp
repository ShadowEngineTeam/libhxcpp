#include <hxcpp.h>

#include <map>
#include <vector>
#include <set>
#include <cstdio>
#include <cstring>
#include <stdlib.h>

#if defined(HXCPP_CAPTURE_x64) && !defined(__GNUC__)
#include <windows.h>
#endif


#ifdef _WIN32

#define GC_WIN32_THREADS
#include <time.h>

#endif

#ifdef HXCPP_TELEMETRY
extern void __hxt_new_string(void* result, int size);
#endif




namespace hx
{
#if defined(HX_MACOS) || defined(HX_WINDOWS) || defined(HX_LINUX) || defined(__ORBIS__)
size_t sgMinimumWorkingMemory       = 20*1024*1024;
size_t sgMinimumFreeSpace           = 10*1024*1024;
#else
size_t sgMinimumWorkingMemory       = 8*1024*1024;
size_t sgMinimumFreeSpace           = 4*1024*1024;
#endif
// Once you use more than the minimum, this kicks in...
size_t sgTargetFreeSpacePercentage  = 100;






// %zu would take "-1" as SIZE_MAX
static bool parseSize(const char *inText, size_t &outValue)
{
   return !strchr(inText, '-') && 1 == std::sscanf(inText, "%zu", &outValue);
}

// Called internally before and GC operations
void CommonInitAlloc()
{
    // It is probably safe to use something like strtoull for parsing the size_t values as I'm sure every reasonable implementation treats them as uint64_t.
    // But just to be pedantic let's use sscanf which is the only "official" way to do this in C++11.
    // C++17 gives us std::charconv but I haven't twisted enough arms yet to have 17 be the minimum version.

   #if !defined(HX_WINRT) && !defined(__SNC__) && !defined(__ORBIS__)
   const char *minimumWorking{ getenv("HXCPP_MINIMUM_WORKING_MEMORY") };
   if (minimumWorking && *minimumWorking)
   {
       if (!parseSize(minimumWorking, sgMinimumWorkingMemory))
       {
           hx::CriticalError(HX_CSTRING("Failed to parse number from HXCPP_MINIMUM_WORKING_MEMORY environment variable"));
       }
   }

   const char* minimumFreeSpace{ getenv("HXCPP_MINIMUM_FREE_SPACE") };
   if (minimumFreeSpace && *minimumFreeSpace)
   {
       if (!parseSize(minimumFreeSpace, sgMinimumFreeSpace))
       {
           hx::CriticalError(HX_CSTRING("Failed to parse number from HXCPP_MINIMUM_FREE_SPACE environment variable"));
       }
   }

   const char* targetFree{ getenv("HXCPP_TARGET_FREE_SPACE") };
   if (targetFree && *targetFree)
   {
       if (!parseSize(targetFree, sgTargetFreeSpacePercentage))
       {
           hx::CriticalError(HX_CSTRING("Failed to parse number from HXCPP_TARGET_FREE_SPACE environment variable"));
       }
   }
   #endif
}

} // end namespace hx



void *String::operator new( size_t inSize )
{
   return hx::InternalNew(inSize,false);
}


void __hxcpp_collect(bool inMajor)
{
   hx::InternalCollect(inMajor,inMajor);
}


namespace hx { size_t InternalCompactBytes(); }

void __hxcpp_gc_compact()
{
   size_t mem = hx::InternalCompactBytes();
   while(true)
   {
      size_t compact = hx::InternalCompactBytes();
      if (compact+16384>=mem)
         break;
      mem = compact;
   }
}

namespace hx
{

void GCAddFinalizer(hx::Object *v, finalizer f)
{
   if (v)
   {
      throw Dynamic(HX_CSTRING("Add finalizer error"));
   }
}

HX_CHAR *NewString(int inLen)
{
   // Strings long enough for rehashing to be noticeable get four extra
   // bytes after the terminator, where String::hash() memoizes the hash on
   // first use
   bool hashSlot = inLen >= HX_GC_STRING_HASH_SLOT_MIN_LEN;
   char *result =  (char *)hx::InternalNew( (inLen+1)*sizeof(char) + (hashSlot ? 4 : 0), false );
   result[inLen] = '\0';
   if (hashSlot)
      ((unsigned int *)result)[-1] |= HX_GC_STRING_HASH_SLOT;
#ifdef HXCPP_TELEMETRY
   __hxt_new_string(result, inLen+1);
#endif
   return result;

}

char *NewStringUncleared(int inLen)
{
   bool hashSlot = inLen >= HX_GC_STRING_HASH_SLOT_MIN_LEN;
   char *result =  (char *)hx::InternalNewUncleared( (inLen+1)*sizeof(char) + (hashSlot ? 4 : 0) );
   // The terminator and the hash slot, which the caller does not fill
   memset(result + inLen, 0, 1 + (hashSlot ? 4 : 0));
   if (hashSlot)
      ((unsigned int *)result)[-1] |= HX_GC_STRING_HASH_SLOT;
#ifdef HXCPP_TELEMETRY
   __hxt_new_string(result, inLen+1);
#endif
   return result;
}

// A copy writes every byte before anything else can see the buffer
void *NewGCBytes(void *inData, size_t inSize)
{
   void *result =  inData ? hx::InternalNewUncleared(inSize) : hx::InternalNew(inSize,false);
   if (inData)
   {
      memcpy(result,inData,inSize);
   }
   return result;
}


void *NewGCPrivate(void *inData, size_t inSize)
{
   void *result =  inData ? InternalNewUncleared(inSize) : InternalNew(inSize,false);
   if (inData)
   {
      memcpy(result,inData,inSize);
   }
   return result;
}



} // end namespace hx




void __hxcpp_enable(bool inEnable)
{
   hx::InternalEnableGC(inEnable);
}

void  __hxcpp_set_minimum_working_memory(int inBytes)
{
   hx::sgMinimumWorkingMemory = inBytes<0 ? 0 : inBytes;
}

void  __hxcpp_set_minimum_free_space(int inBytes)
{
   hx::sgMinimumFreeSpace = inBytes<0 ? 0 : inBytes;
}

void  __hxcpp_set_target_free_space_percentage(int inPercentage)
{
   hx::sgTargetFreeSpacePercentage = inPercentage<0 ? 0 : inPercentage;
}

bool __hxcpp_is_const_string(const ::String &inString)
{
   #ifdef HXCPP_ALIGN_ALLOC
   // Unaligned must be native const
   if ( ((size_t)inString.__s) & 0x3 )
      return true;
   #endif
   return ((unsigned int *)inString.raw_ptr())[-1] & HX_GC_CONST_ALLOC_BIT;
}

