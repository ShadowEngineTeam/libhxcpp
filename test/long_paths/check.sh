#!/usr/bin/env bash
# Long generated file names (libhxcpp #356). Usage: test/long_paths/check.sh
#
# Everywhere: a source with a 64 character name builds, and its object file
# name is cut to 48 characters plus the directory hash.
# On Windows with cl.exe: the same build from a folder deep enough that the
# source path passes 260 characters warns that cl.exe cannot open it.

set -u
cd "$(dirname "$0")"
failures=0
fail() {
   echo "FAIL $1"
   failures=$((failures + 1))
}

rm -rf obj out
if ! haxelib run hxcpp Build.xml; then
   fail "the build with a long source name failed"
elif [ "$(out/longname | tr -d '\r')" != 42 ]; then
   fail "the program did not print 42"
fi
for obj in $(find obj -name '*TimerTable*' -type f); do
   name=$(basename "$obj")
   name=${name%.*}
   # 8 hex digits and an underscore come before the kept name
   if [ ${#name} -gt $((9 + 48)) ]; then
      fail "object file name $name has ${#name} characters"
   else
      echo "ok   object file name $name"
   fi
done

case "$(uname -s)" in
MINGW*|MSYS*|CYGWIN*)
   deep=$(mktemp -d)/$(printf 'd%.0s' $(seq 1 150))
   mkdir -p "$deep/src"
   cp Build.xml "$deep/"
   cp src/*.cpp "$deep/src/"
   output=$(cd "$deep" && haxelib run hxcpp Build.xml 2>&1)
   echo "$output"
   if grep -qF "260 character limit" <<< "$output" && grep -qF "libhxcpp #356" <<< "$output"; then
      echo "ok   long path warning"
   else
      fail "no warning about the 260 character limit"
   fi
   rm -rf "$(dirname "$deep")"
   ;;
esac
exit $failures
