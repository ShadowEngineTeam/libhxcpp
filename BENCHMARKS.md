# Benchmarks

The benchmark suite in [bench](bench) compares libhxcpp with stock hxcpp 4.3.53, the release Lime's CI builds desktop and mobile targets with. The [README](README.md#performance) shows a short summary of the key measures; this page has every result.

## Results

<!-- bench:start -->
**Speed** (higher is better)

| Benchmark | Unit | libhxcpp | hxcpp 4.3.53 | libhxcpp vs stock |
| --- | --- | ---: | ---: | ---: |
| alloc_small | objects/s | 589M ±1.1% | 593M ±0.7% | ~0.99x |
| alloc_strings | strings/s | 48M ±0.3% | 23.7M ±0.2% | 2.03x |
| alloc_arrays | arrays/s | 20.2M ±0.8% | 20.7M ±0.4% | 0.98x |
| gc_pauses | objects/s | 90.6M ±2.3% | 59.8M ±1.4% | 1.51x |
| map_int | map operations/s | 130M ±1.6% | 123M ±2.4% | 1.05x |
| map_string | map operations/s | 31.2M ±4% | 23.2M ±1.7% | 1.34x |
| map_object | map operations/s | 10.1M ±3.6% | 10.2M ±2.7% | ~0.99x |
| string_build | appends/s | 64.8M ±0.8% | 41.7M ±2.3% | 1.56x |
| string_index | indexOf calls/s | 1.9M ±0.6% | 213k ±0.7% | 9.0x |
| string_substr | substr calls/s | 81.2M ±0.5% | 82.4M ±0.3% | 0.99x |
| string_split | split calls/s | 28k ±0.4% | 22.8k ±0.6% | 1.23x |
| string_case | case conversions/s | 37.7M ±0.5% | 1.5M ±0.3% | 25.03x |
| sort_int | elements/s | 3.8M ±4.6% | 3.1M ±0.3% | 1.21x |
| sort_string | elements/s | 1.5M ±1.9% | 1.2M ±1.9% | 1.32x |
| sort_object | elements/s | 4.3M ±0.7% | 4.1M ±0.3% | 1.05x |

**Collection pauses and memory** (lower is better)

| Metric | Benchmark | libhxcpp | hxcpp 4.3.53 | stock / libhxcpp |
| --- | --- | ---: | ---: | ---: |
| Startup and exit | noop | 4 ms | 2.5 ms | 0.63x |
| Work unit time, p99 | gc_pauses | 54.2 us | 75.2 us | 1.39x |
| Work unit time, p99.9 | gc_pauses | 4.7 ms | 11.9 ms | 2.54x |
| Work unit time, max | gc_pauses | 5.7 ms | 17.2 ms | 3.02x |
| Peak memory | alloc_small | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | alloc_strings | 26.3 MB | 24.8 MB | 0.94x |
| Peak memory | alloc_arrays | 29.5 MB | 28.3 MB | 0.96x |
| Peak memory | gc_pauses | 136 MB | 131 MB | 0.96x |
| Peak memory | map_int | 32.4 MB | 30.6 MB | 0.94x |
| Peak memory | map_string | 134 MB | 110 MB | 0.82x |
| Peak memory | map_object | 73 MB | 68.3 MB | 0.94x |
| Peak memory | string_build | 30.7 MB | 228 MB | 7.43x |
| Peak memory | string_index | 10.9 MB | 8.4 MB | 0.78x |
| Peak memory | string_substr | 26.4 MB | 24.9 MB | 0.94x |
| Peak memory | string_split | 70 MB | 72.4 MB | 1.03x |
| Peak memory | string_case | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | sort_int | 32.7 MB | 27.7 MB | 0.85x |
| Peak memory | sort_string | 34.9 MB | 30.3 MB | 0.87x |
| Peak memory | sort_object | 29.4 MB | 27.9 MB | 0.95x |

Windows, AMD Ryzen 9 9950X 16-Core Processor; MSVC 194435213, 64-bit; Haxe 4.3.7; libhxcpp 51939949; 3 processes x 10 samples per benchmark; 2026-10-20 16:08:27.
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
