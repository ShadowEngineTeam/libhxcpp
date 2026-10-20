# libhxcpp

[![main](https://github.com/openfl/libhxcpp/actions/workflows/main.yml/badge.svg)](https://github.com/openfl/libhxcpp/actions/workflows/main.yml)
[![License: BSD](https://img.shields.io/badge/license-BSD-blue.svg)](LICENSE.txt)

libhxcpp is the runtime for the C++ target of the [Haxe](https://haxe.org/) compiler: the headers, garbage collector, standard library and build tool that turn the C++ Haxe generates into a native program. It continues hxcpp from its full history. It is installed as the haxelib `libhxcpp`, and one setup command makes everything that asks for hxcpp use it, so existing projects need no changes.

## Highlights

- **More than 170 fixes and improvements on top of hxcpp 4.3.** Garbage collector correctness (moving GC heap corruption, `HXCPP_GC_BIG_BLOCKS`, threads that start or end during a collection), memory-safety bugs reachable from plain Haxe code, sockets and TLS (mbedTLS 3.6 LTS, TLS 1.3, session resumption), MySQL 8 and SQLite, string and number formatting that matches the other Haxe targets, and faster maps, strings, sorting and cppia. [Changes.md](Changes.md) lists them all.
- **Tested releases.** A release is cut deliberately from a commit CI has tested, and ships with the build tool and the cppia host prebuilt for Windows, macOS and Linux.
- **Broad CI.** Every change runs the test suites on Windows (32 and 64-bit), macOS (x86_64 and Arm64) and Linux (32 and 64-bit) with Haxe 4.3.7, runs the GC tests with big blocks, compiles the GC under 32 define configurations at both block sizes, and checks installing with haxelib. The same suites run against the Haxe nightly build once a day.
- **Open development.** Issues and pull requests are welcome.

## Performance

The benchmark suite in [bench](bench) builds the same Haxe sources twice, once against libhxcpp and once against stock hxcpp 4.3.53 (the release Lime's CI builds with), with the same Haxe, C++ compiler and flags, and runs them one benchmark per process. The latest results:

<!-- bench:start -->
**Speed** (higher is better)

| Benchmark | Unit | libhxcpp | hxcpp 4.3.53 | libhxcpp vs stock |
| --- | --- | ---: | ---: | ---: |
| alloc_small | objects/s | 590M ±1% | 596M ±0.4% | ~0.99x |
| alloc_strings | strings/s | 49.3M ±0.3% | 23.7M ±0.3% | 2.09x |
| alloc_arrays | arrays/s | 20.8M ±0.5% | 20.5M ±0.8% | ~1.01x |
| gc_pauses | objects/s | 87.6M ±3% | 59.3M ±1.4% | 1.48x |
| map_int | map operations/s | 128M ±1% | 123M ±0.8% | 1.04x |
| map_string | map operations/s | 30.2M ±2.7% | 21.8M ±3.2% | 1.38x |
| map_object | map operations/s | 8.2M ±1.9% | 9.1M ±5.8% | ~0.91x |
| string_build | appends/s | 65.1M ±1.4% | 41.1M ±2.9% | 1.59x |
| string_index | indexOf calls/s | 1.9M ±1.2% | 212k ±0.8% | 9.03x |
| string_substr | substr calls/s | 85.8M ±0.4% | 83.9M ±0.3% | 1.02x |
| string_split | split calls/s | 29.7k ±0.7% | 22.9k ±0.3% | 1.3x |
| string_case | case conversions/s | 29.2M ±0.3% | 1.5M ±0.2% | 19.36x |
| sort_int | elements/s | 4.1M ±1.9% | 3.2M ±0.7% | 1.29x |
| sort_string | elements/s | 1.3M ±1.8% | 1.2M ±2.6% | 1.15x |
| sort_object | elements/s | 4.4M ±0.2% | 4.1M ±0.3% | 1.05x |

**Collection pauses and memory** (lower is better)

| Metric | Benchmark | libhxcpp | hxcpp 4.3.53 | stock / libhxcpp |
| --- | --- | ---: | ---: | ---: |
| Startup and exit | noop | 4.1 ms | 3.5 ms | 0.87x |
| Work unit time, p99 | gc_pauses | 56.9 us | 70.1 us | 1.23x |
| Work unit time, p99.9 | gc_pauses | 4.8 ms | 11.8 ms | 2.48x |
| Work unit time, max | gc_pauses | 6.6 ms | 14.2 ms | 2.15x |
| Peak memory | alloc_small | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | alloc_strings | 26.3 MB | 24.8 MB | 0.94x |
| Peak memory | alloc_arrays | 29.5 MB | 28.3 MB | 0.96x |
| Peak memory | gc_pauses | 136 MB | 131 MB | 0.96x |
| Peak memory | map_int | 32.2 MB | 30.6 MB | 0.95x |
| Peak memory | map_string | 134 MB | 110 MB | 0.82x |
| Peak memory | map_object | 72.9 MB | 68.7 MB | 0.94x |
| Peak memory | string_build | 30.7 MB | 228 MB | 7.43x |
| Peak memory | string_index | 10.9 MB | 8.4 MB | 0.78x |
| Peak memory | string_substr | 26.3 MB | 24.9 MB | 0.94x |
| Peak memory | string_split | 70 MB | 72.4 MB | 1.03x |
| Peak memory | string_case | 26.3 MB | 24.9 MB | 0.95x |
| Peak memory | sort_int | 32.7 MB | 27.7 MB | 0.85x |
| Peak memory | sort_string | 38.9 MB | 30.3 MB | 0.78x |
| Peak memory | sort_object | 29.4 MB | 27.9 MB | 0.95x |

Windows, AMD Ryzen 9 9950X 16-Core Processor; MSVC 194435213, 64-bit; Haxe 4.3.7; libhxcpp b2456986; 3 processes x 10 samples per benchmark; 2026-10-20 01:21:37.
Reproduce with `cd bench && haxe --run Run`. Ratios above 1 favour libhxcpp; "~" marks a difference within the run-to-run spread.
<!-- bench:end -->

These numbers are from one Windows machine; Linux and macOS results are still to come. Where libhxcpp is still slower than stock hxcpp, that is a bug we are working on, and the [6.0.0 checklist](https://github.com/openfl/libhxcpp/issues/192) tracks it.

## Installing

libhxcpp is a haxelib of its own, `libhxcpp`, that stands in for hxcpp. Install it, then run its setup once:

```
haxelib install libhxcpp
haxelib run libhxcpp setup
```

`main` is the development version of libhxcpp 6.0.0. Until 6.0.0 is published, install it from git instead:

```
haxelib git libhxcpp https://github.com/openfl/libhxcpp
haxelib run libhxcpp setup
```

A git checkout needs its build tool compiled once. The first build offers to do it, or you can do it yourself:

```
cd <the path printed by: haxelib libpath libhxcpp>
cd tools/hxcpp
haxe compile.hxml
```

A release can also be installed from its zip on the [releases](https://github.com/openfl/libhxcpp/releases) page, with the build tool and the cppia host already built: `haxelib install libhxcpp-<version>.zip`, then the setup.

### What setup does

The Haxe compiler, `-lib hxcpp` and libraries that depend on hxcpp all ask haxelib for `hxcpp`. Setup points that name at libhxcpp, with `haxelib dev hxcpp <libhxcpp's folder>`, so they all get the same runtime. hxcpp itself, if it is installed, is not touched.

After `haxelib update libhxcpp`, the next build notices the newer version and moves the redirect to it by itself.

Setup applies to the haxelib repository it runs in, so a project with a local repository (`haxelib newrepo`) can use libhxcpp while other projects keep hxcpp.

### Switching back to hxcpp

```
haxelib run libhxcpp off
```

Everything uses hxcpp again straight away. If hxcpp is not installed, install it with `haxelib install hxcpp`.

## Using libhxcpp

Your project needs no changes. A build that uses the library, as `-lib hxcpp` or `-lib libhxcpp`, gets the defines `hxcpp` and `libhxcpp`, both set to libhxcpp's version, so code can tell which runtime it is built against:

```haxe
#if libhxcpp
// built against libhxcpp
#end

#if (libhxcpp >= version("6.0.1"))
// built against libhxcpp 6.0.1 or newer
#end
```

Compare versions with `version()`. A comparison with a plain string, such as `(libhxcpp >= "6.0.1")`, compares text and goes wrong once a part of the version reaches two digits. In a release, native code can include `HxcppVersion.h` for `LIBHXCPP_VERSION`.

## Sharing mbedTLS with a library

Haxe's TLS (`sys.ssl`, and `haxe.Http` with https) runs on mbedTLS, which libhxcpp bundles. A library that bundles mbedTLS too, such as Lime, can offer its copy: in static builds (iOS, tvOS, `static_link`) libhxcpp then builds its TLS on the library's mbedTLS instead of its own, so the app carries one copy. The library sets the define `hxcpp_mbedtls_provider` to a small provider file describing its mbedTLS; libhxcpp uses it when the mbedTLS major version is one it supports, and its own copy otherwise. [docs/MbedTLSProvider.md](docs/MbedTLSProvider.md) describes how to offer one.

## Compatibility

libhxcpp keeps hxcpp's build XML, defines and API, and works with the code Haxe 4.2 and later generates for hxcpp. A few fixes deliberately change behaviour to match the other Haxe targets, for example how `Std.string` formats floats, NaN and Infinity, and TLS connections now require TLS 1.2 or newer. Changes.md describes each one.

## Versions and releases

libhxcpp follows [semantic versioning](https://semver.org) with its own numbers, starting at 6.0.0. Pre-releases are tagged `-alpha`, `-beta` or `-rc`. Each release is tagged `v<version>`, has its notes in [Changes.md](Changes.md), and is published on haxelib as `libhxcpp` and on the [releases](https://github.com/openfl/libhxcpp/releases) page. [RELEASING.md](RELEASING.md) describes how a release is made.

## Building from source

Build the command-line tools:

```
REPO=$(pwd)
cd ${REPO}/tools/run
haxe compile.hxml
cd ${REPO}/tools/hxcpp
haxe compile.hxml
cd $REPO
```

Build the cppia host:

```
REPO=$(pwd)
cd ${REPO}/project
haxe compile-cppia.hxml
cd $REPO
```

Then you can run a cppia script with `haxelib run hxcpp file.cppia`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for building against a checkout, running the test suites and what a pull request needs. Report problems on the [issue tracker](https://github.com/openfl/libhxcpp/issues).

## License

libhxcpp is under the BSD-style license in [LICENSE.txt](LICENSE.txt), the same as hxcpp. Copyright in hxcpp's code stays with its contributors; the work added since 2025 is copyright Dimensionscape LLC. Bundled third-party libraries keep their own licenses.
