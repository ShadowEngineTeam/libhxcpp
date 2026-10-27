#!/usr/bin/env bash
# Benchmarks this checkout against another commit on the same machine, as
# the bench workflow does (libhxcpp #258).
#
#   bash bench/ci.sh <base-commit> [Run.hx options]
#
# Checks out <base-commit> in bench/.work/base-src, builds the benchmarks in
# bench/src against both runtimes and runs them in turns with Run.hx, then
# reports throughput, tail pauses and peak memory separately with Compare.hx.
# Giving HEAD as the base measures how far the same code varies between two
# builds and runs: an A/A run.
#
# Writes bench/.work/results.json (every sample), bench/.work/report.md and
# bench/.work/history.jsonl (one line for the bench-history branch). Exits
# non-zero only if a build of this checkout or a benchmark fails; regressions
# are reported, as GitHub warnings when run in Actions. BENCH_RUNS and
# BENCH_SAMPLES set the processes per benchmark and the samples per process.

set -eu
if [ $# -lt 1 ]; then
   echo "usage: bash bench/ci.sh <base-commit> [Run.hx options]" >&2
   exit 2
fi
base=$1
shift
cd "$(dirname "$0")"
mkdir -p .work
src=.work/base-src

git worktree remove --force "$src" 2>/dev/null || rm -rf "$src"
# --force reuses the path if an earlier run was stopped before removing it
git worktree add --force --detach "$src" "$base"
trap 'git worktree remove --force "$src"' EXIT

rm -f .work/results.json .work/report.md .work/history.jsonl
status=0
haxe --run Run --base "$src" --runs "${BENCH_RUNS:-3}" --samples "${BENCH_SAMPLES:-5}" --out .work/results.json "$@" || status=$?
if [ ! -f .work/results.json ]; then
   exit $status
fi

compare=(--summary .work/report.md --history .work/history.jsonl)
if [ -n "${GITHUB_ACTIONS:-}" ]; then
   compare+=(--github)
fi
haxe --run Compare .work/results.json "${compare[@]}"
exit $status
