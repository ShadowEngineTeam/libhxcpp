#!/usr/bin/env bash
# Runs the programs in src on C++, cppia (interpreted and jit) and every other
# Haxe target whose tools are installed (JavaScript, HashLink, eval, Neko,
# Python, JVM, PHP), and compares each line of output with C++'s.
#
# cppia shares C++'s runtime, so a difference there that is not listed in
# known-differences.txt fails. The other targets are reported, each differing
# line marked known (with the reason listed) or not explained, for a person to
# look at: Haxe leaves some behaviour to each target.
#
# Usage, from test/targets: bash compare.sh [-D HXCPP_ARM64]
# Needs haxe and haxelib pointing hxcpp at this checkout. HL=<path to hl> picks
# the HashLink binary. Writes out/<target>.txt, out/<target>.diff and
# out/summary.md.

set -u
cd "$(dirname "$0")"
ARCH="${*:--D HXCPP_M64}"
rm -rf out && mkdir -p out
HX="haxe -cp src -main Main"

# run <target> <command...>: the output, with carriage returns dropped
run() {
   local target="$1"
   shift
   if "$@" > "out/$target.txt" 2> "out/$target.err"; then
      tr -d '\r' < "out/$target.txt" > "out/$target.tmp" && mv "out/$target.tmp" "out/$target.txt"
      echo "$target" >> out/ran.txt
   else
      echo "$target failed to run (out/$target.err)" >> out/errors.txt
   fi
}

# build <target> <haxe arguments...>
build() {
   local target="$1"
   shift
   $HX "$@" > "out/$target-build.log" 2>&1 || { echo "$target failed to build (out/$target-build.log)" >> out/errors.txt; return 1; }
}

have() { command -v "$1" > /dev/null 2>&1; }

build cpp -cpp out/cpp $ARCH || { cat out/errors.txt; tail -20 out/cpp-build.log; exit 1; }
run cpp out/cpp/Main

if build cppia -cppia out/main.cppia; then
   host=$(ls ../../bin/*/Cppia ../../bin/*/Cppia.exe 2>/dev/null | head -1)
   if [ -z "$host" ]; then
      (cd ../../project && haxe compile-cppia.hxml $ARCH) > out/host-build.log 2>&1
      host=$(ls ../../bin/*/Cppia ../../bin/*/Cppia.exe 2>/dev/null | head -1)
   fi
   if [ -n "$host" ]; then
      run cppia "$host" out/main.cppia
      run cppia-jit "$host" -jit out/main.cppia
   else
      echo "cppia host failed to build (out/host-build.log)" >> out/errors.txt
   fi
fi

have node && build js -js out/main.js && run js node out/main.js
HL="${HL:-hl}"
have "$HL" && build hl -hl out/main.hl && run hl "$HL" out/main.hl
run eval $HX --interp
have neko && build neko -neko out/main.n && run neko neko out/main.n
PY=$(have python3 && echo python3 || (have python && echo python))
[ -n "$PY" ] && build python -python out/main.py && run python "$PY" out/main.py
have java && haxelib path hxjava > /dev/null 2>&1 && build jvm --jvm out/main.jar && run jvm java -jar out/main.jar
have php && build php -php out/php && run php php out/php/index.php

failed=0
{
   echo "## Output compared with C++"
   echo
   echo "Ran: $(tr '\n' ' ' < out/ran.txt)"
   echo
   while read -r target; do
      [ "$target" = cpp ] && continue
      diff out/cpp.txt "out/$target.txt" > "out/$target.diff"
      lines=$(grep -c '^>' "out/$target.diff")
      gated=$([[ "$target" == cppia* ]] && echo yes || echo no)
      echo "### $target: $lines line(s) differ"
      echo
      [ "$lines" -eq 0 ] && continue
      while IFS= read -r line; do
         label="${line#> }"
         label="${label%%:*}"
         reason=$(awk -F'\t' -v t="$target" -v l="$label" '$1==t && $2==l {print $3}' known-differences.txt)
         if [ -n "$reason" ]; then
            echo "- \`$label\`: known, $reason"
         else
            echo "- \`$label\`: **not explained**"
            [ "$gated" = yes ] && failed=1
         fi
      done < <(grep '^>' "out/$target.diff")
      echo
      echo '```diff'
      cat "out/$target.diff"
      echo '```'
      echo
   done < out/ran.txt
   if [ -f out/errors.txt ]; then
      echo "### Errors"
      echo
      sed 's/^/- /' out/errors.txt
      # The end of each failing target's own output says why it failed
      for err in out/*.err; do
         target=$(basename "$err" .err)
         grep -q "^$target failed" out/errors.txt || continue
         echo
         echo "$target:"
         echo '```'
         tail -n 8 "$err"
         echo '```'
      done
   fi
} > out/summary.md
grep -q '^cpp\(ia\)\? failed\|^cppia' out/errors.txt 2>/dev/null && failed=1

cat out/summary.md
exit $failed
