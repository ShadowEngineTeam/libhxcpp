# hxcpp tests

The tests here are hxcpp specific. Notice that there are more target independent tests available in the [haxe repo](https://github.com/HaxeFoundation/haxe).

## Running the tests

haxe --run RunTests

## Fuzzing

[fuzz](fuzz) has fuzz targets for the parsers and decoders that read untrusted input: the cppia loader, UTF-8 and UTF-16 strings, Bytes, Serializer, Json, EReg, number parsing, URL decoding and zlib. `bash test/fuzz/run.sh [seconds]` builds them with libFuzzer and ASan (and UBSan with clang) and runs each target; `bash test/fuzz/run.sh --replay` runs the seed corpus and every input that once failed, with any compiler. The fuzz workflow runs them for 30 seconds a target on each change and 10 minutes daily.
