# libhxcpp

[![main](https://github.com/openfl/libhxcpp/actions/workflows/main.yml/badge.svg)](https://github.com/openfl/libhxcpp/actions/workflows/main.yml)
[![License: BSD](https://img.shields.io/badge/license-BSD-blue.svg)](LICENSE.txt)

libhxcpp is the runtime for the C++ target of the [Haxe](https://haxe.org/) compiler: the headers, garbage collector, standard library and build tool that turn the C++ Haxe generates into a native program. It continues hxcpp from its full history and installs under the name `hxcpp`, so existing projects use it without changes.

## Highlights

- **More than 170 fixes and improvements on top of hxcpp 4.3.** Garbage collector correctness (moving GC heap corruption, `HXCPP_GC_BIG_BLOCKS`, threads that start or end during a collection), memory-safety bugs reachable from plain Haxe code, sockets and TLS (mbedTLS 3.6 LTS, TLS 1.3, session resumption), MySQL 8 and SQLite, string and number formatting that matches the other Haxe targets, and faster maps, strings, sorting and cppia. [Changes.md](Changes.md) lists them all.
- **Tested releases.** A release is cut deliberately from a commit CI has tested, and ships with the build tool and the cppia host prebuilt for Windows, macOS and Linux.
- **Broad CI.** Every change runs the test suites on Windows (32 and 64-bit), macOS (x86_64 and Arm64) and Linux (32 and 64-bit) with Haxe 4.3.7 and the Haxe nightly build, runs the GC tests with big blocks, and compiles the GC under 32 define configurations at both block sizes.
- **Open development.** Issues and pull requests are welcome.

## Installing

`main` is the development version of libhxcpp 6.0.0. Until its first release is published, install it from git.

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

It installs as `hxcpp` and becomes the current version, with the build tool and the cppia host already built.

### Switching back to hxcpp

```
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp
```

or `haxelib set hxcpp <version>` for a release you have installed.

## Using libhxcpp

Your project needs no changes: the Haxe compiler uses whichever library is installed as `hxcpp`. A build that uses the library (`-L hxcpp`) also gets the define `libhxcpp`, set to its version, so code can tell which runtime it is built against:

```haxe
#if libhxcpp
// built against libhxcpp
#end

#if (libhxcpp >= version("6.0.1"))
// built against libhxcpp 6.0.1 or newer
#end
```

Compare versions with `version()`. A comparison with a plain string, such as `(libhxcpp >= "6.0.1")`, compares text and goes wrong once a part of the version reaches two digits. In a release, native code can include `HxcppVersion.h` for `LIBHXCPP_VERSION`.

## Compatibility

libhxcpp keeps hxcpp's name, build XML, defines and API, and works with the code the Haxe compiler generates for hxcpp. A few fixes deliberately change behaviour to match the other Haxe targets, for example how `Std.string` formats floats, NaN and Infinity, and TLS connections now require TLS 1.2 or newer. Changes.md describes each one.

## Versions and releases

libhxcpp follows [semantic versioning](https://semver.org) with its own numbers, starting at 6.0.0. Pre-releases are tagged `-alpha`, `-beta`, `-preview` or `-rc`. Each release is tagged `v<version>`, has its notes in [Changes.md](Changes.md), and is published on the [releases](https://github.com/openfl/libhxcpp/releases) page. [RELEASING.md](RELEASING.md) describes how a release is made.

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
