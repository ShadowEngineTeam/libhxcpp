#!/bin/sh
# Builds Main for Emscripten with the default link settings, runs it under
# node and compares its output with stdout.txt.
# Needs EMSDK set (and EM_CONFIG if emsdk_env was not run), and haxelib
# pointing hxcpp at this checkout.
# Usage: test/emscripten/run.sh [extra haxe args]

cd "$(dirname "$0")"
haxe build.hxml "$@" || { echo "Failed to build"; exit 1; }
if ! actual=$(node bin/Main.js); then
   echo "Failed: return code was $?"
   exit 1
fi
expected=$(tr -d '\r' < stdout.txt)
actual=$(printf '%s' "$actual" | tr -d '\r')
if [ "$actual" != "$expected" ]; then
   echo "Failed: output did not match"
   echo "Expected stdout:"
   echo "$expected"
   echo "Actual stdout:"
   echo "$actual"
   exit 1
fi
echo "Emscripten test passed"
