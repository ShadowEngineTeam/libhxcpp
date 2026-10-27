# Releasing a cppia module

A host that loads replacement cppia code into a running process, for example to reload an application's UI inside a window that stays open, can release the module it is replacing:

```haxe
var module = cpp.cppia.Module.fromData(bytes.getData());
module.boot();
module.run();

// later, once the old generation's UI, callbacks and worker activity are detached
untyped module.release();
module = null;
```

The std's `cpp.cppia.Module` extern does not declare `release`, so call it with `untyped` as above. Native hosts can call `hx::CppiaLoadedModule_obj::release()` directly.

## What release does

- Removes the module's classes from the class registry, so `Type.resolveClass` no longer finds them. A name is only removed if the registry still points at this module's class: releasing an older module leaves a newer module's class of the same name in place. A class the older module had replaced is not brought back.
- Clears the module's script statics (object and String values, and static dynamic functions). Whatever only those statics kept alive, such as a UI tree, loaded assets or caches, can then be collected. Numeric statics keep their values.
- Unregisters the module's resources, if they are the ones currently registered. Strings already read from them stay valid.

Calling `release` more than once does nothing more.

## When its code is freed

After release, the module's code (its expressions, class tables, interface tables and JIT code) is freed by the first full collection that finds nothing still reaching the module. Until then it stays loaded, so references to the old generation stay safe:

- Instances, closures, bound methods, enum values, enum constructors and `Class` values from the released module keep it loaded while anything holds them, and keep working. They see its statics cleared, and a static assigned again after release is kept alive as before.
- Code from the released module that is still running on any thread keeps it loaded and finishes normally.
- Exception stacks that show functions of the released module stay readable after it is freed; they keep copies of those positions.
- Strings read from its resources are copies, so they stay valid too.

A module that fails to load is freed the same way, since the host never gets it.

Repeated reloads do not grow memory: each generation is freed once the host has dropped it.

## Limitations

- **Profiler and telemetry builds keep released modules.** With `HXCPP_PROFILER` or `HXCPP_TELEMETRY` (including Tracy), release still unregisters the module's classes, clears its statics and unregisters its resources, but its code is never freed. Those tools record function names by address and read them later, so freeing the code would leave them pointing at freed memory. Memory then grows with each reload, as it did before modules could be freed; use such builds for profiling, not for long reload sessions.
- **Freeing can lag by a collection or two.** The collector finds references on thread stacks conservatively, so a stale pointer to the module left on a stack by earlier calls keeps it loaded until later calls overwrite it. A host that checks for freeing, as the regression test does, should do the reload in a function that has returned, and collect from elsewhere.
- **With `HXCPP_GC_GENERATIONAL`, a full collection frees it.** Minor collections keep every released module's data marked, since script code writes into it without write barriers, so a released module normally waits for the next full collection.

## Contract

Release a module after its UI, callbacks and worker activity have been detached from the host. Release does not stop code that is running; it only makes the module's statics and names unreachable from now on. Objects from the old generation that the host still holds are not freed by release; they are collected once the host drops them, like any other object, and the module's code goes with the last of them.

`__scriptable_cppia_live_modules()` returns the number of modules whose code has not been freed yet, loaded or released, for hosts and tests that want to check that reloads are freed.

## Finding what keeps a released module loaded

`__scriptable_cppia_retained()` runs a full collection, then returns one row for each released module still loaded after it:

```haxe
for (row in (untyped __global__.__scriptable_cppia_retained() : Array<Dynamic>)) {
	trace('module ${row.module}: ${row.closures.count} closures, ${row.closures.bytes} bytes');
	for (i in (row.instances : Array<Dynamic>))
		trace('  ${i.name}: ${i.count} instances, ${i.bytes} bytes');
}
```

- `module` numbers the module in load order, from 1.
- `instances` lists the live instances of the module's classes by class, with counts and bytes, most bytes first.
- `closures` counts the live bound methods of its functions and its closures that hold an object or captured variables.

It works in release builds, like `__hxcpp_gc_census()`, on which it builds. Not counted, since the module holds them itself while it is loaded: its `Class` objects, its enum values, and its static functions used as values. A host holding one of those keeps the module loaded too. Code of the module still running on a thread, and stale pointers to it left on a stack (see Limitations), keep it loaded without anything being counted.

To find what holds the instances of a class, build the host with `-debug` and call `cpp.vm.Gc.trace` with that class, kept from before the release, since `Type.resolveClass` no longer finds it: it prints the path from a root to each instance.
