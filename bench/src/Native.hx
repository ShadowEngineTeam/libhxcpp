package;

/**
	Process-level facts that Haxe can't report itself. Kept in its own class
	so that windows.h only reaches this one generated file.

	Everything here must compile against both libhxcpp and stock hxcpp, so it
	only uses plain C/C++ and returns string literals or numbers.
**/
@:cppFileCode('
#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <psapi.h>
#if defined(_MSC_VER)
#pragma comment(lib, "psapi.lib")
#endif
#else
#include <sys/resource.h>
#endif

#define BENCH_STR2(x) #x
#define BENCH_STR(x) BENCH_STR2(x)

static double bench_peak_rss()
{
#if defined(_WIN32)
	PROCESS_MEMORY_COUNTERS pmc;
	if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
		return (double)pmc.PeakWorkingSetSize;
	return -1;
#else
	struct rusage ru;
	if (getrusage(RUSAGE_SELF, &ru) != 0)
		return -1;
#if defined(__APPLE__)
	return (double)ru.ru_maxrss;
#else
	return (double)ru.ru_maxrss * 1024.0;
#endif
#endif
}

static const char *bench_compiler()
{
#if defined(__clang__)
	return "clang " __clang_version__;
#elif defined(_MSC_VER)
	return "MSVC " BENCH_STR(_MSC_FULL_VER);
#elif defined(__GNUC__)
	return "gcc " __VERSION__;
#else
	return "unknown";
#endif
}
')
class Native {
	/** Peak resident memory of this process in bytes (peak working set on Windows), or -1. **/
	public static function peakRss():Float {
		return untyped __cpp__("bench_peak_rss()");
	}

	/** The C++ compiler and version this executable was built with. **/
	public static function compiler():String {
		return untyped __cpp__("::String(bench_compiler())");
	}

	public static function pointerBits():Int {
		return untyped __cpp__("(int)(sizeof(void *) * 8)");
	}
}
