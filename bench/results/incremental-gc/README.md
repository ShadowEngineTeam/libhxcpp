# Incremental GC development measurements

These results compare the existing libhxcpp collector with the experimental incremental mode in the same source tree. They do not replace the stock-hxcpp comparison in [BENCHMARKS.md](../../../BENCHMARKS.md). Both collectors use the same benchmark sources, optimized compiler settings and payload checks.

The raw process results, sample times, latency summaries, checksums, peak working sets, reserved heap sizes and incremental counters are in [windows-x64-20261026.json](windows-x64-20261026.json). The containing commit identifies the implementation; the JSON also records the base revision and source hashes.

## Results

Elapsed time is the median of the 15 measured samples. Latency columns show the largest per-process p99.9 and the largest observed work-unit duration across the three processes; the p99.9 column is not a pooled percentile. Memory columns show the largest process value.

| Workload | Collector | Elapsed, ms | Worst p99.9, ms | Maximum, ms | Peak RSS, MiB | Reserved heap, MiB |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `gc_frames` | Existing | 240.246 | 7.742 | 9.728 | 128.76 | 115.36 |
| `gc_frames` | Incremental | 294.961 | 0.969 | 1.858 | 131.98 | 118.29 |
| `gc_pauses` | Existing | 145.429 | 5.055 | 8.289 | 135.29 | 121.55 |
| `gc_pauses` | Incremental | 256.843 | 2.718 | 5.232 | 135.52 | 122.51 |

All six `gc_frames` processes returned checksum 1106626610; all six `gc_pauses` processes returned 458711266. Incremental mode reduced tail latency on these workloads, with 22.8% more elapsed time for `gc_frames` and 76.6% more for `gc_pauses`. That corresponds to 18.5% and 43.4% less throughput, respectively. Neither meets the proposed maximum 10% throughput loss.

The largest budgeted collector invocation was 1.346 ms in `gc_frames` and 1.783 ms in `gc_pauses`, against a requested 0.5 ms. Cumulative unbudgeted maxima were 13.553 ms and 9.971 ms, respectively, including explicit collections outside measured frames. These results do not establish a sub-millisecond collector or eliminate synchronous interruptions.

## Protocol

- Windows x64, AMD Ryzen 9 9950X, Haxe 4.3.7 and MSVC 19.44.35213.
- Default block size, existing collector defaults versus `HXCPP_GC_INCREMENTAL` with its default 0.5 ms target and 1 ms preferred interval.
- No `HXCPP_GC_INCREMENTAL_VERIFY`, `HXCPP_GC_INCREMENTAL_TEST`, scriptable mode or explicit engine scheduling hooks.
- Three processes per workload and collector, two warmups and five measured samples per process. Collector order alternates between processes. Compilation, stress and sanitizer runs finished before measurement.
- `gc_frames` retains 150,000 entities and runs 2,000 frames per sample. Frame timing includes graph and inventory changes, temporary particles and event strings, fixed-size spatial cells and periodic bursts. Payload validation runs after the frame loop and is included in elapsed sample time.
- `gc_pauses` retains a large graph and records 3,000 allocation work units per sample. A work unit is not a game frame or an isolated GC pause.
- The harness requests a full collection before each sample, outside its timed section. Cumulative GC counters include setup, warmups, these explicit collections and validation. Their maxima cannot be presented as maxima of GC work inside measured frames.
- Checksums must agree across all processes of a workload. The JSON contains elapsed sample times and per-process latency summaries, rather than a trace of individual frames.

## Reproduction

After pointing haxelib at this checkout as described in CONTRIBUTING.md, build each mode sequentially:

```sh
haxe -cp bench/src -main Main -cpp build/gc-default -lib hxcpp -D HXCPP_M64
haxe -cp bench/src -main Main -cpp build/gc-incremental -lib hxcpp -D HXCPP_M64 -D HXCPP_GC_INCREMENTAL
```

For each workload, run the following pair three times, reversing the order in the second pair. On Windows the executable is `Main.exe`.

```sh
build/gc-default/Main gc_frames --warmup 2 --samples 5
build/gc-incremental/Main gc_frames --warmup 2 --samples 5
build/gc-default/Main gc_pauses --warmup 2 --samples 5
build/gc-incremental/Main gc_pauses --warmup 2 --samples 5
```

## Correctness validation

Local Windows validation includes all nine phase and lifecycle fixtures listed in [IncrementalGc.md](../../../docs/IncrementalGc.md), with the independent verifier and deterministic controls, at normal and big block sizes. Each block size also passed three 30-second stress runs with eight threads and seeds 2012663045, 1337 and 8675309. The full runtime suite passed 1,100 assertions with incremental verification and big blocks. The new slice, container and finishing fixtures also pass with the existing collector, and the container and finishing fixtures pass in single-threaded incremental builds.

Linux under WSL, Haxe 4.3.3 and GCC 13.3 passed ASan and UBSan builds of the slice, container and finishing fixtures, plus a 30-second stress run with eight threads under each sanitizer. Leak detection is disabled because these runs exercise the runtime's conservative stack scanning configuration. They are not leak measurements. The final GCC define matrix passed all 79 configurations, including incremental, verification/test and single-threaded variants at both block sizes.

The independent verifier fixture deliberately omits a reachable descendant's mark in a child process and requires rejection. The epoch recovery assertion failed before the recovery fix, and the allocation cursor assertion failed before preserving allocator ranges across partial slices.

Local TSan did not reach a usable test run: the installed GCC runtime rejected the repository suppression syntax and, without suppressions, failed under WSL before the workload ran. TSan and other platform results remain for CI. CI configuration includes incremental regressions and stress in the sanitizer jobs and a native incremental job on supported Haxe 4 configurations.

## Remaining gates

This is experimental. The throughput target in [#372](https://github.com/openfl/libhxcpp/issues/372) is still open. Weak closure, finalizers, reclamation, root capture, thread rendezvous and forced completion can exceed the slice target. Longer soaks, additional memory-pressure and native-integration coverage, pause distributions for all stopped threads, progress and metadata high-water counters, and cross-platform results are still needed before considering a default change.
