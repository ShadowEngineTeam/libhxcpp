# Benchmarks

The benchmark suite in [bench](bench) compares libhxcpp with stock hxcpp 4.3.53, the release Lime's CI builds desktop and mobile targets with. The [README](README.md#performance) shows a short summary of the key measures; this page has every result.

## Results

<!-- bench:start -->
**Speed** (higher is better)

| Benchmark | Unit | libhxcpp | hxcpp 4.3.53 | libhxcpp vs stock |
| --- | --- | ---: | ---: | ---: |
| alloc_small | objects/s | 576M ±2.3% | 578M ±1.1% | ~1.0x |
| alloc_strings | strings/s | 50.3M ±0.4% | 23.6M ±0.4% | 2.13x |
| alloc_arrays | arrays/s | 20M ±1.1% | 20.3M ±1% | ~0.99x |
| gc_pauses | objects/s | 82.5M ±2.2% | 53.2M ±3.2% | 1.55x |
| map_int | map operations/s | 124M ±2.7% | 119M ±2.6% | ~1.04x |
| map_string | map operations/s | 25.4M ±8.3% | 19.7M ±3% | 1.29x |
| map_object | map operations/s | 8.4M ±3.4% | 7.9M ±4% | ~1.06x |
| string_build | appends/s | 62.7M ±1.9% | 40M ±2.5% | 1.56x |
| string_index | indexOf calls/s | 1.8M ±2% | 210k ±0.6% | 8.46x |
| string_substr | substr calls/s | 85.5M ±1.4% | 82.9M ±0.6% | 1.03x |
| string_split | split calls/s | 28.5k ±1.1% | 22.7k ±0.6% | 1.26x |
| string_case | case conversions/s | 37.7M ±0.5% | 1.5M ±0.2% | 24.94x |
| sort_int | elements/s | 4M ±2% | 3.2M ±0.9% | 1.24x |
| sort_string | elements/s | 1.5M ±2.5% | 1.2M ±1.9% | 1.27x |
| sort_object | elements/s | 4.3M ±0.6% | 4.1M ±0.6% | 1.06x |

**CPPIA speed** (higher is better)

| Workload | Unit | Interpreter, libhxcpp | Interpreter, hxcpp 4.3.53 | Interpreter vs stock | JIT, libhxcpp | JIT, hxcpp 4.3.53 | JIT vs stock |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| int_loop | iterations/s | 48M ±0.5% | 46.8M ±0.4% | 1.03x | 733M ±3.1% | 736M ±2.5% | ~1.0x |
| float_array | elements/s | 24.5M ±0.6% | 25.5M ±0.4% | 0.96x | 216M ±0.5% | 221M ±0.9% | 0.98x |
| alloc_objects | objects/s | 18.1M ±0.3% | 18.5M ±0.4% | 0.98x | 102M ±0.6% | 105M ±0.8% | 0.97x |
| virtual_call | calls/s | 38.5M ±0.4% | 38.8M ±0.3% | 0.99x | 294M ±0.2% | 294M ±0.3% | ~1.0x |
| closure_call | calls/s | 20M ±0.3% | 21M ±0.3% | 0.95x | 25.5M ±0.6% | 26.4M ±0.4% | 0.96x |
| native_call | calls/s | 73.3M ±0.2% | 74.2M ±0.2% | 0.99x | 606M ±0.9% | 604M ±0.9% | ~1.0x |
| native_callback | callbacks/s | 27.1M ±0.3% | 28.3M ±0.1% | 0.96x | 27M ±0.7% | 28M ±0.4% | 0.96x |

**Collection pauses and memory** (lower is better)

| Metric | Benchmark | libhxcpp | hxcpp 4.3.53 | stock / libhxcpp |
| --- | --- | ---: | ---: | ---: |
| Startup and exit | noop | 3.5 ms | 3.3 ms | 0.94x |
| Work unit time, p99 | gc_pauses | 64.4 us | 83.2 us | 1.29x |
| Work unit time, p99.9 | gc_pauses | 5.1 ms | 12.7 ms | 2.51x |
| Work unit time, max | gc_pauses | 6.4 ms | 18.2 ms | 2.86x |
| Peak memory | alloc_small | 25.3 MB | 24.9 MB | 0.98x |
| Peak memory | alloc_strings | 25.4 MB | 24.8 MB | 0.98x |
| Peak memory | alloc_arrays | 28.5 MB | 28.3 MB | 0.99x |
| Peak memory | gc_pauses | 135 MB | 131 MB | 0.97x |
| Peak memory | map_int | 31.4 MB | 30.6 MB | 0.97x |
| Peak memory | map_string | 133 MB | 110 MB | 0.83x |
| Peak memory | map_object | 72 MB | 68.4 MB | 0.95x |
| Peak memory | string_build | 29.7 MB | 228 MB | 7.68x |
| Peak memory | string_index | 9.9 MB | 8.4 MB | 0.85x |
| Peak memory | string_substr | 25.4 MB | 24.9 MB | 0.98x |
| Peak memory | string_split | 69 MB | 72.4 MB | 1.05x |
| Peak memory | string_case | 25.3 MB | 24.9 MB | 0.98x |
| Peak memory | sort_int | 32 MB | 27.7 MB | 0.87x |
| Peak memory | sort_string | 33.9 MB | 30.3 MB | 0.89x |
| Peak memory | sort_object | 28.4 MB | 27.9 MB | 0.98x |
| Peak memory | cppia_interp_int_loop | 7.3 MB | 8.3 MB | 1.14x |
| Peak memory | cppia_interp_float_array | 28 MB | 29 MB | 1.04x |
| Peak memory | cppia_interp_alloc_objects | 22.7 MB | 23.8 MB | 1.05x |
| Peak memory | cppia_interp_virtual_call | 7.3 MB | 8.4 MB | 1.14x |
| Peak memory | cppia_interp_closure_call | 27.8 MB | 28.9 MB | 1.04x |
| Peak memory | cppia_interp_native_call | 7.3 MB | 8.3 MB | 1.13x |
| Peak memory | cppia_interp_native_callback | 27.9 MB | 28.8 MB | 1.04x |
| Peak memory | cppia_jit_int_loop | 7.5 MB | 8.5 MB | 1.13x |
| Peak memory | cppia_jit_float_array | 7.6 MB | 8.6 MB | 1.14x |
| Peak memory | cppia_jit_alloc_objects | 22.9 MB | 23.9 MB | 1.04x |
| Peak memory | cppia_jit_virtual_call | 7.5 MB | 8.5 MB | 1.14x |
| Peak memory | cppia_jit_closure_call | 28 MB | 29 MB | 1.04x |
| Peak memory | cppia_jit_native_call | 7.5 MB | 8.5 MB | 1.13x |
| Peak memory | cppia_jit_native_callback | 28 MB | 29 MB | 1.04x |

Windows, AMD Ryzen 9 9950X 16-Core Processor; MSVC 194435213, 64-bit; Haxe 4.3.7; libhxcpp 6b740dcc; 3 processes x 10 samples per benchmark; 2026-10-21 11:13:39.
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

### CPPIA

Each workload below has two benchmark names, `cppia_interp_<workload>` and
`cppia_jit_<workload>`. A full run includes both modes on both runtimes. The
driver also checks that the interpreter and JIT return the same checksum.

| Workload | What it measures |
| --- | --- |
| `int_loop` | Integer arithmetic, bit operations and branches in a script loop |
| `float_array` | Float arithmetic, typed array reads and writes, and Float-to-Int conversion |
| `alloc_objects` | 125,000 script objects per call, with Int and object fields and a bounded live graph |
| `virtual_call` | Virtual calls alternating between two script implementations |
| `closure_call` | Script calls to a closure that updates a captured variable |
| `native_call` | Script-to-native calls with an Int argument and result |
| `native_callback` | A native loop calling a script closure that updates a captured variable |

The native timing harness loads one script module per process. Loading, linking,
booting and JIT compilation happen in `setup()`, outside the timed samples.
These measure execution after loading, not module startup or reload. Each sample
repeats its workload enough times to keep timer overhead small, and the operation
count includes every repetition.

The script classes live in `bench/cppia/Script.hx` and are compiled only to
CPPIA. `bench/cppia/shared` defines the interface and native bridge exported by
the host and imported by the script with `dll_export` and `dll_import`. The host
uses `scriptable` and `--dce no`, like the CPPIA tests. It is a separate executable
so those flags do not change the native benchmarks. Peak memory for these cases
includes the host, loaded module and any JIT code. The `noop` startup row still
measures the native executable.

## Running it yourself

You need Haxe 4.3, the C++ compiler hxcpp uses on your platform, and curl.

```sh
cd bench
haxe --run Run                       # every benchmark, both runtimes
haxe --run Run --only map_int,sort_int
haxe --run Run --only cppia_interp_native_call,cppia_jit_native_call
haxe --run Run --no-build            # reuse the last builds
haxe --run Run --readme              # publish: this page and the README summary
```

`--readme` needs every benchmark, both runtimes and a committed tree, so the published numbers always name the commit they were measured on. The driver's [doc comment](bench/Run.hx) lists every option.

## Adding a benchmark

1. Add the class to [bench/src](bench/src) and register it in `Main.hx`. For a CPPIA workload, add its script implementation in `bench/cppia/Script.hx` and register both modes in `CppiaBenchmarks.all()`.
2. Add a row to the table above.
3. If it covers something most programs depend on, add it to `SUMMARY` in `Run.hx` so it also shows in the README. Keep that table short; everything else belongs here.
4. Run `haxe --run Run --readme` from a committed tree and commit the result, so this page and the README stay current.
