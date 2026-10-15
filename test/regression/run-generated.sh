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
   if ! (cd "$test/bin" && neko "$root/hxcpp.n" Build.xml -DHXCPP="$root/" > build.log 2>&1); then
      echo "Failed to build test $test"
      tail -30 "$test/bin/build.log"
      continue
   fi
   if ! actual=$("$test/bin/Main"); then
      echo "Test $test failed: return code was $?"
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
