#!/bin/sh
# Builds Main with Embind, as Emscripten executables link by default, and
# calls a bound function, then with HXCPP_LINK_NO_EMBIND, and checks that the
# JavaScript has none of Embind's registration code. Each is run under node
# and its output compared with stdout.txt or stdout-no-embind.txt.
# Needs what test/emscripten/run.sh does.
# Usage: test/emscripten/embind/run.sh [extra haxe args]

cd "$(dirname "$0")"

check() {
   if ! actual=$(node $1/Main.js); then
      echo "Failed: $1 return code was $?"
      exit 1
   fi
   expected=$(tr -d '\r' < $2)
   actual=$(printf '%s' "$actual" | tr -d '\r')
   if [ "$actual" != "$expected" ]; then
      echo "Failed: $1 output did not match"
      echo "Expected stdout:"
      echo "$expected"
      echo "Actual stdout:"
      echo "$actual"
      exit 1
   fi
}

haxe build.hxml --cpp bin/bound "$@" || { echo "Failed to build with Embind"; exit 1; }
check bin/bound stdout.txt
if ! grep -q _embind_register bin/bound/Main.js; then
   echo "Failed: the build with Embind has no Embind registration"
   exit 1
fi

haxe build.hxml --cpp bin/unbound -D no_bindings -D HXCPP_LINK_NO_EMBIND "$@" || { echo "Failed to build without Embind"; exit 1; }
check bin/unbound stdout-no-embind.txt
if grep -q _embind_register bin/unbound/Main.js; then
   echo "Failed: HXCPP_LINK_NO_EMBIND left Embind in"
   exit 1
fi
echo "Emscripten Embind test passed: $(wc -c < bin/bound/Main.js) bytes of JavaScript with Embind, $(wc -c < bin/unbound/Main.js) without"
