# Homura's hxcpp Fork (OpenFL Edition)

This hxcpp fork was previously used for the Android and iOS ports I provided. Although it is no longer used for those ports, it is still maintained and continues to exist for the Shadow Engine.

# License

This hxcpp fork is licensed under the MIT License. See [LICENSE](LICENSE) for details.

# Building the Tools

With Lime:
```
haxelib run lime rebuild hxcpp
```

Otherwise:
```
cd "$(haxelib libpath hxcpp)/tools/run"
haxe compile.hxml
cd "$(haxelib libpath hxcpp)/tools/hxcpp"
haxe compile.hxml
```
