#!/bin/sh
# Builds Main with native wasm exceptions, the default, and with
# HXCPP_NO_WASM_EXEPTIONS, runs each under node and compares its output with
# stdout.txt. Needs what test/emscripten/run.sh does.
# Usage: test/emscripten/exceptions/run.sh [extra haxe args]

cd "$(dirname "$0")"

run() {
   dir=$1
   shift
   haxe build.hxml --cpp $dir "$@" || { echo "Failed to build $dir"; exit 1; }
   if ! actual=$(node $dir/Main.js); then
      echo "Failed: $dir return code was $?"
      exit 1
   fi
   expected=$(tr -d '\r' < stdout.txt)
   actual=$(printf '%s' "$actual" | tr -d '\r')
   if [ "$actual" != "$expected" ]; then
      echo "Failed: $dir output did not match"
      echo "Expected stdout:"
      echo "$expected"
      echo "Actual stdout:"
      echo "$actual"
      exit 1
   fi
}

run bin/wasm "$@"
run bin/js -D HXCPP_NO_WASM_EXEPTIONS "$@"
echo "Emscripten exception test passed"
