# When a script needs what the host does not have

A cppia script is compiled against a host's classes, but it may be loaded by a different build of that host: a plugin or a content package built separately, or a script rebuilt against a newer host. When the script uses a class or member that this host does not have, `cpp.cppia.Module.fromData` fails, before any of the script runs, with one String naming everything missing:

```
Could not link new Foo, static function Foo.make, static Settings.volume, Player.jump (Level.hx:42)
```

Catch it to tell the user what is wrong:

```haxe
try {
	var module = cpp.cppia.Module.fromData(bytes.getData());
	module.boot();
	module.run();
} catch (e:String) {
	showError('This plugin needs a newer version of the app: $e');
}
```

Each missing thing is named once, with the first place the script uses it when the script was compiled with `-debug`.

## What is checked

- `new` of a class the host does not have: `new Foo`
- a static function or static field of a class the host does not have, or that the host's class does not have: `static function Foo.make`, `static Settings.volume`
- a call or read, on a value typed as a host class, of a member that class does not have: `Player.jump`
- an Array method the runtime does not have: `Array.someMethod`

A script class whose super class is not in the host, or a script interface whose functions match no host interface, cannot be laid out at all, so the load fails at once with that one class named: `Could not link class Enemy: the host has no super class Actor`.

## What is not checked

Members are checked against the host class's reflected fields. A class that reflects no fields, such as an `@:unreflective` one, is not checked, and anything reached through `Dynamic`, an anonymous structure or `Reflect` is looked up only when it runs, as in native code.
