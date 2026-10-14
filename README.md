# libhxcpp

[![main](https://github.com/openfl/libhxcpp/actions/workflows/main.yml/badge.svg)](https://github.com/openfl/libhxcpp/actions/workflows/main.yml)

libhxcpp is the runtime support for the C++ backend of the [Haxe](https://haxe.org/) compiler: the headers, libraries and support code needed to compile Haxe code into a native executable. It continues hxcpp from its full history, and it installs under the name `hxcpp`, so the Haxe compiler uses it with no change to your project.

## Why libhxcpp

- **Fixes and improvements on top of hxcpp 4.3.** More than 150 changes, including garbage collector correctness (moving GC heap corruption, `HXCPP_GC_BIG_BLOCKS`, roots of threads that exit), memory-safety bugs reachable from plain Haxe code, sockets and TLS (mbedTLS 3.6 LTS, TLS 1.3), MySQL 8 and SQLite, string and number formatting that matches the other Haxe targets, and faster maps, strings and cppia. The full list is in [Changes.md](Changes.md).
- **Releases with everything prebuilt.** A libhxcpp release carries the build tool and the cppia host for Windows, macOS and Linux. hxcpp's last haxelib release was 4.3.2, in April 2023.
- **Tested on every change.** CI runs the test suites on Windows (32 and 64-bit), macOS (x86_64 and Arm64) and Linux (32 and 64-bit) with Haxe 4.3.7 and the Haxe nightly build, runs the GC tests with big blocks, and compiles the GC under 32 define configurations at both block sizes.
- **Open to contributions.** Issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Install

`main` is the development version of libhxcpp 6.0.0. Until the first release is published, install it from git.

### From git

```
haxelib git hxcpp https://github.com/openfl/libhxcpp
```

A git checkout needs its build tool compiled once. The first build offers to do it, or you can do it yourself:

```
cd <the path printed by: haxelib libpath hxcpp>
cd tools/hxcpp
haxe compile.hxml
```

### From a release

Download `libhxcpp-<version>.zip` from the [releases](https://github.com/openfl/libhxcpp/releases) and install it:

```
haxelib install libhxcpp-<version>.zip
```

It installs as `hxcpp` and becomes the current version. The build tool and cppia host are already built.

### Going back to hxcpp

```
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp
```

or `haxelib set hxcpp <version>` for a release you have installed.

## Versions

libhxcpp has its own version numbers, starting at 6.0.0; they do not follow hxcpp's. A build that uses the library (`-L hxcpp`) gets the define `libhxcpp`, set to the version, so code can check which runtime it is on:

```haxe
#if libhxcpp
// built against libhxcpp
#end

#if (libhxcpp >= version("6.0.1"))
// built against libhxcpp 6.0.1 or newer
#end
```

Compare versions with `version()`. A comparison with a plain string, such as `(libhxcpp >= "6.0.1")`, compares text and goes wrong once a part of the version reaches two digits.

## Compatibility

libhxcpp keeps hxcpp's name, build XML, defines and API, and works with the code the Haxe compiler generates for hxcpp. A few fixes deliberately change behaviour to match the other Haxe targets, for example how `Std.string` formats floats, NaN and Infinity, and TLS connections now require TLS 1.2 or newer. Changes.md describes each one.

## Building the tools

```
REPO=$(pwd)
cd ${REPO}/tools/run
haxe compile.hxml
cd ${REPO}/tools/hxcpp
haxe compile.hxml
cd $REPO
```

## cppia

You first need to build the cppia host.

```
REPO=$(pwd)
cd ${REPO}/project
haxe compile-cppia.hxml
cd $REPO
```

Then you can do `haxelib run hxcpp file.cppia`.

## License

libhxcpp is under the BSD-style license in [LICENSE.txt](LICENSE.txt), the same as hxcpp. Copyright in hxcpp's code stays with its contributors; the work added since 2025 is copyright Dimensionscape LLC. Bundled third-party libraries keep their own licenses.
