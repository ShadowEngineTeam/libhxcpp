# Benchmarks

The benchmark suite in [bench](bench) compares libhxcpp with stock hxcpp 4.3.53, the release Lime's CI builds desktop and mobile targets with. The [README](README.md#performance) shows a short summary of the key measures; this page has every result.

## Results

<!-- bench:start -->
<!-- bench:end -->

These numbers are from one Windows machine; Linux and macOS results are still to come. Where libhxcpp is slower or uses more memory than stock hxcpp, that is a bug, and the [6.0.0 checklist](https://github.com/openfl/libhxcpp/issues/192) tracks it.

## How the comparison works

- **Same program, two runtimes.** The driver builds the same Haxe sources twice, with the same Haxe, C++ compiler and flags: once against this checkout and once against the stock release, downloaded from GitHub as Lime's CI does. Each runtime gets its own local haxelib repository, and the driver checks which hxcpp each build actually used and that both used the same compiler and word size. On Windows both builds are 64-bit.
- **One benchmark per process.** Each benchmark runs in its own process, so peak memory belongs to that benchmark alone: the peak working set on Windows, the maximum resident set size elsewhere. Each process does 2 untimed warm-up samples and 10 timed samples, and there are 3 processes per benchmark and runtime. The runtimes take turns, so drift on the machine affects both alike.
- **Same work, checked.** Every benchmark returns a checksum of the work it did, and every process under both runtimes has to produce the same one. A change that skips work or computes the wrong answer fails the run instead of looking faster.
- **Spread.** "±" is the median absolute deviation of the sample times, as a percentage of the median. A ratio marked "~" is within twice the larger spread of the two runtimes, so it counts as level.

## The benchmarks

| Benchmark | What it measures |
| --- | --- |
| `alloc_small` | Small objects, almost all short-lived; the last 1024 stay reachable |
| `alloc_strings` | Int-to-String conversion plus a concatenation per string |
| `alloc_arrays` | Arrays of 1 to 64 Ints grown by `push`, plus a 256 KB buffer every 4000 arrays |
| `gc_pauses` | Collection pauses as the program sees them: a large live graph stays reachable while the program allocates in fixed work units, and each unit's duration is recorded. The tail holds the units that included a collection |
| `map_int` | `IntMap`: on a fresh map, N sets, N hits, N misses, N/2 removes, then iterating the N/2 values left |
| `map_string` | `StringMap`, the same cycle |
| `map_object` | `ObjectMap`, the same cycle |
| `string_build` | `StringBuf` appends of words, spaces and Ints, turned into a String every 64 rounds |
| `string_index` | `indexOf` from spread-out start positions; about half the needles are found |
| `string_substr` | `substr` of short slices, read back with `charCodeAt` |
| `string_split` | `split` of a text on spaces |
| `string_case` | `toUpperCase` and `toLowerCase` of a 64-character line |
| `sort_int` | `Array<Int>` sorted with a comparator closure |
| `sort_string` | `Array<String>` sorted with `Reflect.compare` |
| `sort_object` | Objects sorted by an Int field, with repeated keys |
| `noop` | Starting the program and exiting at once (startup time, measured 20 times per runtime) |

## Running it yourself

You need Haxe 4.3, the C++ compiler hxcpp uses on your platform, and curl.

```sh
cd bench
haxe --run Run                       # every benchmark, both runtimes
haxe --run Run --only map_int,sort_int
haxe --run Run --no-build            # reuse the last builds
haxe --run Run --readme              # publish: this page and the README summary
```

`--readme` needs every benchmark, both runtimes and a committed tree, so the published numbers always name the commit they were measured on. The driver's [doc comment](bench/Run.hx) lists every option.

## Adding a benchmark

1. Add the class to [bench/src](bench/src) and register it in `Main.hx`.
2. Add a row to the table above.
3. If it covers something most programs depend on, add it to `SUMMARY` in `Run.hx` so it also shows in the README. Keep that table short; everything else belongs here.
4. Run `haxe --run Run --readme` from a committed tree and commit the result, so this page and the README stay current.
