# Benchmarks

The benchmark suite in [bench](bench) compares libhxcpp with stock hxcpp 4.3.53, the release Lime's CI builds desktop and mobile targets with. The [README](README.md#performance) shows a short summary of the key measures; this page has every result.

## Results

<!-- bench:start -->
**Speed** (higher is better)

| Benchmark | Unit | libhxcpp | hxcpp 4.3.53 | libhxcpp vs stock |
| --- | --- | ---: | ---: | ---: |
| alloc_small | objects/s | 584M ±1% | 590M ±0.7% | ~0.99x |
| alloc_strings | strings/s | 50.1M ±0.3% | 23.7M ±0.3% | 2.11x |
| alloc_arrays | arrays/s | 20.4M ±0.7% | 20M ±2.1% | ~1.02x |
| gc_pauses | objects/s | 89.3M ±2.5% | 60M ±1.2% | 1.49x |
| map_int | map operations/s | 131M ±0.5% | 126M ±0.7% | 1.04x |
| map_string | map operations/s | 31.4M ±2.8% | 23.2M ±1.9% | 1.36x |
| map_object | map operations/s | 10M ±3.6% | 9.6M ±3.7% | ~1.04x |
| string_build | appends/s | 64.7M ±1.1% | 42.2M ±2.4% | 1.53x |
| string_index | indexOf calls/s | 2.1M ±1.3% | 213k ±0.6% | 9.64x |
| string_substr | substr calls/s | 87.6M ±0.3% | 83.2M ±0.5% | 1.05x |
| string_split | split calls/s | 29.5k ±0.5% | 23k ±0.2% | 1.28x |
| string_case | case conversions/s | 38.2M ±0.2% | 1.5M ±0.1% | 25.17x |
| sort_int | elements/s | 4.2M ±1.1% | 3.2M ±0.4% | 1.32x |
| sort_string | elements/s | 1.3M ±1.4% | 1.2M ±1% | 1.12x |
| sort_object | elements/s | 4.4M ±0.1% | 4.2M ±0.3% | 1.05x |

**Collection pauses and memory** (lower is better)

| Metric | Benchmark | libhxcpp | hxcpp 4.3.53 | stock / libhxcpp |
| --- | --- | ---: | ---: | ---: |
| Startup and exit | noop | 4.1 ms | 3 ms | 0.73x |
| Work unit time, p99 | gc_pauses | 56.2 us | 65.9 us | 1.17x |
| Work unit time, p99.9 | gc_pauses | 4.7 ms | 11.7 ms | 2.5x |
| Work unit time, max | gc_pauses | 6.6 ms | 13.7 ms | 2.09x |
| Peak memory | alloc_small | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | alloc_strings | 26.4 MB | 24.8 MB | 0.94x |
| Peak memory | alloc_arrays | 29.5 MB | 28.3 MB | 0.96x |
| Peak memory | gc_pauses | 136 MB | 131 MB | 0.96x |
| Peak memory | map_int | 32.4 MB | 30.6 MB | 0.94x |
| Peak memory | map_string | 134 MB | 110 MB | 0.82x |
| Peak memory | map_object | 72.9 MB | 68.4 MB | 0.94x |
| Peak memory | string_build | 30.7 MB | 228 MB | 7.43x |
| Peak memory | string_index | 10.9 MB | 8.4 MB | 0.77x |
| Peak memory | string_substr | 26.4 MB | 24.9 MB | 0.94x |
| Peak memory | string_split | 70 MB | 72.4 MB | 1.03x |
| Peak memory | string_case | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | sort_int | 33 MB | 27.7 MB | 0.84x |
| Peak memory | sort_string | 39 MB | 30.3 MB | 0.78x |
| Peak memory | sort_object | 29.4 MB | 27.9 MB | 0.95x |

Windows, AMD Ryzen 9 9950X 16-Core Processor; MSVC 194435213, 64-bit; Haxe 4.3.7; libhxcpp 80f1f82f; 3 processes x 10 samples per benchmark; 2026-10-20 11:06:23.
Reproduce with `cd bench && haxe --run Run`. Ratios above 1 favour libhxcpp; "~" marks a difference within the run-to-run spread.
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
