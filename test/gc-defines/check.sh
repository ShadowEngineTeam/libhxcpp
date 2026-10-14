#!/usr/bin/env bash
# Compile the GC under each of its defines, at the default and big block sizes.
#
# Most GC defines are not built by any test, so code behind them can stop
# compiling without anyone noticing. This runs the compiler's checks on
# src/hx/gc/Immix.cpp for every configuration below (no object files are
# written) and fails if any of them does not compile.
#
# Usage: test/gc-defines/check.sh [compiler]   (default: g++)

set -u
cd "$(dirname "$0")/../.."

export CXX="${1:-g++}"
export BASE_FLAGS="-fsyntax-only -frtti -Wno-invalid-offsetof -Iinclude -DHX_LINUX -DHXCPP_M64 -DHXCPP_VISIT_ALLOCS -DHX_SMART_STRINGS -DHXCPP_API_LEVEL=430"

# One configuration per entry, defines joined with commas.
# HXCPP_EXPLICIT_STACK_EXTENT is left out: it is only defined for Emscripten
# single-threaded builds and needs Emscripten's headers.
CONFIGS=(
   none
   HXCPP_GC_MOVING
   HXCPP_GC_MOVING,HXCPP_GC_DEBUG_ALWAYS_MOVE
   HXCPP_GC_GENERATIONAL
   HXCPP_GC_GENERATIONAL,HX_GC_VERIFY_GENERATIONAL
   HXCPP_GC_VERIFY
   HXCPP_GC_VERIFY,HX_GC_VERIFY_ALLOC_START
   HXCPP_GC_VERIFY,HXCPP_GC_MOVING
   HXCPP_GC_VERIFY,HXCPP_GC_GENERATIONAL
   HX_GC_VERIFY_ALLOC_START
   HX_GC_FIXED_BLOCKS
   HXCPP_GC_DYNAMIC_SIZE
   HXCPP_GC_SUMMARY
   HXCPP_GC_CHECK_POINTER
   HXCPP_GC_NURSERY
   HXCPP_GC_DEBUG_LEVEL=1
   HXCPP_GC_DEBUG_LEVEL=2
   HXCPP_GC_DEBUG_LEVEL=3
   HXCPP_GC_DEBUG_LEVEL=4
   HXCPP_SINGLE_THREADED_APP
   HX_MULTI_THREAD_MARKING
   HXCPP_ALIGN_ALLOC
   HXCPP_TELEMETRY
   HXCPP_DEBUG
   HXCPP_SCRIPTABLE
   HX_WATCH
   SHOW_FRAGMENTATION
   SHOW_FRAGMENTATION,SHOW_FRAGMENTATION_BLOCKS
   SHOW_MEM_EVENTS
   SHOW_MEM_EVENTS,SHOW_MEM_EVENTS_VERBOSE
   PROFILE_COLLECT
   PROFILE_THREAD_USAGE
)

# Prints one line per configuration, with the first error when it fails.
check_one() {
   local size="$1" config="$2" flags="" d out
   [ "$size" = big ] && flags="-DHXCPP_GC_BIG_BLOCKS"
   if [ "$config" != none ]; then
      for d in ${config//,/ }; do flags="$flags -D$d"; done
   fi
   if out=$($CXX $BASE_FLAGS $flags src/hx/gc/Immix.cpp 2>&1); then
      echo "ok   [$size] $config"
   else
      echo "FAIL [$size] $config :: $(echo "$out" | grep -m1 "error")"
   fi
}
export -f check_one

results=$(
   for size in default big; do
      for config in "${CONFIGS[@]}"; do
         echo "$size $config"
      done
   done | xargs -P "$(nproc 2>/dev/null || echo 2)" -L 1 bash -c 'check_one "$0" "$1"' | sort
)

echo "$results"
total=$(echo "$results" | grep -c "^\(ok\|FAIL\)")
failures=$(echo "$results" | grep -c "^FAIL")
echo "$total configurations, $failures failed"
[ "$failures" -eq 0 ]
