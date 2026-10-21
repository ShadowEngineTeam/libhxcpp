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

## What stays

The module's code stays loaded: its expressions, class tables, interface tables and JIT code. Each reload therefore keeps roughly the size of its `.cppia` file in native memory, but none of the data the old generation built. Keeping the code is what makes release safe while references to the old generation remain:

- Instances, closures, bound methods, enum values and `Class` values from the released module keep working. They see its statics cleared, and a static assigned again after release is kept alive as before.
- Code from the released module that is still running on any thread finishes normally.
- Stack traces that point into the released module stay readable.

## Contract

Release a module after its UI, callbacks and worker activity have been detached from the host. Release does not stop code that is running; it only makes the module's statics and names unreachable from now on. Objects from the old generation that the host still holds are not freed by release; they are collected once the host drops them, like any other object.
