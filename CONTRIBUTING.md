# Contributing to libhxcpp

Issues and pull requests are welcome.

## Reporting a problem

Say which Haxe and libhxcpp versions you use, the platform and C++ compiler, and any defines that matter (`HXCPP_GC_MOVING`, `HXCPP_GC_BIG_BLOCKS`, `HXCPP_DEBUG`...). A small program that shows the problem is the most useful thing you can add.

## Working on libhxcpp

Point haxelib at your checkout and build the build tool once:

```
haxelib dev hxcpp <path to your checkout>
cd <path to your checkout>/tools/hxcpp
haxe compile.hxml
```

`haxelib dev hxcpp` with no path switches back to the version you had installed.

## Tests

Each suite builds against the checkout haxelib points at. Use `-D HXCPP_M32`, `-D HXCPP_M64` or `-D HXCPP_ARM64` for the architecture.

| Suite | Directory | Build | Run |
|---|---|---|---|
| Runtime and GC | `test/haxe` | `haxe compile.hxml -D HXCPP_M64` | `bin/TestMain` |
| Standard library | `test/std` | `haxe compile64.hxml` | `cpp64/Test` |
| Regressions, one program each | `test/regression` | `haxe --run Run -D HXCPP_M64` | (runs them) |
| GC defines (Linux or WSL, g++) | repository root | `test/gc-defines/check.sh` | (runs them) |

`test/haxe` needs the `utest` library. `test/std` needs `hx4compat` and utest from git (`haxelib git utest https://github.com/haxe-utest/utest`).

## Pull requests

- Open them against `main`, one fix or feature each.
- Add a test that fails without the change when one is possible: a case in `test/haxe` or `test/std`, or a program of its own in `test/regression` when the problem needs a fresh process (a crash, something at exit, a race).
- Say what was wrong and how the change fixes it, in the pull request and in the commit message.
- Add a line to the unreleased section at the top of [Changes.md](Changes.md) for anything a user would notice. Releases themselves are described in [RELEASING.md](RELEASING.md).

## License

Contributions are made under the project's license, in [LICENSE.txt](LICENSE.txt). You keep the copyright in what you contribute.
