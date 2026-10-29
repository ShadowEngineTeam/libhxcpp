#!/bin/sh
# Builds and runs the regression tests from C++ that Haxe generated elsewhere
# with -D no-compilation, for a host without Haxe. Needs neko and hxcpp.n.
# Usage: test/regression/run-generated.sh

cd "$(dirname "$0")"
root=$(cd ../.. && pwd)
# The tests share the runtime, so it compiles once
export HXCPP_COMPILE_CACHE="${HXCPP_COMPILE_CACHE:-${TMPDIR:-/tmp}/hxcpp-cache}"
total=0
successes=0
for test in */; do
   test=${test%/}
   [ -f "$test/build.hxml" ] || continue
   total=$((total + 1))
   # Haxe passes -debug to the build tool on its command line and leaves it
   # out of Options.txt, so a debug test would build as a release one. Only
   # the section that makes bin counts: a cppia script's -debug is its own
   debug=
   if tr -d '' < "$test/build.hxml" | awk '
         /^[[:space:]]*--next/ { if (cpp && dbg) found=1; cpp=0; dbg=0; next }
         /^[[:space:]]*-?-cpp[[:space:]]+bin[[:space:]]*$/ { cpp=1 }
         /^[[:space:]]*-?-debug[[:space:]]*$/ { dbg=1 }
         END { exit !(found || (cpp && dbg)) }'; then
      debug=-Ddebug
   fi
   if ! (cd "$test/bin" && neko "$root/hxcpp.n" Build.xml -DHXCPP="$root/" $debug > build.log 2>&1); then
      echo "Failed to build test $test"
      tail -30 "$test/bin/build.log"
      continue
   fi
   # A host that an earlier --next section compiled, which -D no-compilation
   # does not reach, was built where Haxe ran, so it is built again here
   for host in "$test"/bin/*/Build.xml; do
      [ -f "$host" ] || continue
      if ! (cd "${host%/Build.xml}" && neko "$root/hxcpp.n" Build.xml -DHXCPP="$root/" > build.log 2>&1); then
         echo "Failed to build the host ${host%/Build.xml} of test $test"
         tail -30 "${host%/Build.xml}/build.log"
         continue 2
      fi
   done
   # An ndll the test loads was built where Haxe ran, for that system, so it
   # is built again here
   if [ -f "$test/native/Build.xml" ] && ! (cd "$test/native" && rm -rf obj ndll && neko "$root/hxcpp.n" Build.xml -DHXCPP="$root/" > build.log 2>&1); then
      echo "Failed to build the native fixture of test $test"
      tail -30 "$test/native/build.log"
      continue
   fi
   actual=$("$test/bin/Main")
   code=$?
   if [ $code -ne 0 ]; then
      echo "Test $test failed: return code was $code"
      continue
   fi
   expected=$(tr -d '\r' < "$test/stdout.txt")
   if [ "$actual" != "$expected" ]; then
      echo "Test $test failed: Output did not match"
      echo "Expected stdout:"
      echo "$expected"
      echo "Actual stdout:"
      echo "$actual"
      continue
   fi
   successes=$((successes + 1))
done
echo "Regression tests complete. Successes: $successes / $total"
[ "$successes" -eq "$total" ]
