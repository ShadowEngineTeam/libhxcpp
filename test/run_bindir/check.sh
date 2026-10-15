#!/usr/bin/env bash
# run.n hands the build to the BuildTool compiled for this host, in bin/<dir>
# Usage: test/run_bindir/check.sh <expected bin dir>

set -eu
cd "$(dirname "$0")/../.."
dir=bin/$1
created=
if [ ! -e hxcpp.n ]; then
   : > hxcpp.n
   created=1
fi
mkdir -p "$dir"
trap 'rm -rf "$dir"; [ -z "$created" ] || rm -f hxcpp.n' EXIT
printf '#!/bin/sh\necho compiled BuildTool\n' > "$dir/BuildTool"
chmod +x "$dir/BuildTool"

out=$(HXCPP_NONINTERACTIVE=1 neko run.n 2>&1 || true)
if [ "$out" != "compiled BuildTool" ]; then
   echo "FAIL run.n did not run $dir/BuildTool:"
   echo "$out"
   exit 1
fi
echo "ok   run.n ran $dir/BuildTool"
