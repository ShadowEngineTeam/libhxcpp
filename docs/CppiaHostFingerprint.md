# Tying a cppia script to its host

A script is compiled against one build of its host: `-D dll_export=host.info` on the host lists what it exports, and `-D dll_import=host.info` on the script leaves those classes out of the `.cppia` file. Nothing in the file says which host it was built for, so a script built against an older or newer host loads until linking reaches something the host no longer has, or calls through something that changed.

A host fingerprint lets a script require the host it was built for.

## The fingerprint

`__scriptable_host_fingerprint()` returns 16 hexadecimal digits standing for what the host gives scripts:

- every class registered for scripts, with its super class, its constructor's and functions' names and signatures, and its member and static fields' names and storage types;
- every interface registered for scripts, with its functions' names and signatures.

The same host source built the same way gives the same fingerprint, on any machine and in any run. Field offsets are left out, so 32-bit and 64-bit builds of one source agree; anything a script can link against or call differently gives a different fingerprint. It is worked out once, the first time it is asked for.

From Haxe:

```haxe
var fingerprint:String = untyped __global__.__scriptable_host_fingerprint();
```

The Cppia host that `haxelib run hxcpp script.cppia` runs, `bin/<platform>/Cppia` in the library, prints its own:

```
bin/Windows64/Cppia.exe -fingerprint
```

## Requiring it

A script that carries a resource named `__cppia_host` loads only into a host whose fingerprint matches it. Write the host's fingerprint to a file and embed it when building the script:

```
haxe -main Script -D dll_import=host.info -resource host-fingerprint.txt@__cppia_host -cppia script.cppia
```

Spaces and line breaks around the digits are ignored. Loading checks the resource before linking, and a mismatch fails to load, with a String the host can catch from `Module.fromData`:

```
This cppia module was built for host 3f2a9c0d81e4b765, but this host is 0b7d21e6c95fa018
```

A script without the resource loads as before.
