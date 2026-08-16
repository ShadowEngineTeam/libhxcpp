package cases;

import cpp.cppia.Host;
import cpp.vm.Gc;
import cpp.vm.WeakRef;
import utest.Test;
import utest.Assert;

private class HostOne implements pack.HostInterface
{
    public static var called = 0;

    public function new() {}

    public function getOne() : Int {
        called ++;
        return 1;
    }

    public function getOneString() : String {
        called++;
        return "1";
    }
}

class TestCommon extends Test {
    function setupClass() {  
        Common.hostImplementation = new HostOne();
    
        Common.callback = () -> Common.callbackSet = 1;

        Host.main();
    }

    function testStatus() {
        Assert.equals('ok', Common.status);
    }

    @:depends(testStatus)
    function testClientImplementation() {
        Assert.equals(2, HostOne.called, 'No client implementation call');

        if (Assert.notNull(Common.clientImplementation, 'No client implementation')) {
            Assert.equals(1, Common.clientImplementation.getOne(), 'Bad client Int implementation');
            Assert.equals('1', Common.clientImplementation.getOneString(), 'Bad client String implementation');
        }
    }

    @:depends(testStatus)
    function testResolvingScriptType() {
        var hostBase:HostBase = Type.createInstance(Type.resolveClass("ClientExtends2"),[]);
        if (Assert.notNull(hostBase, 'Failed to create client type')) {
            Assert.isTrue(hostBase.testUpdateOverride(), 'Bad update override');
        }
    }

    @:depends(testStatus)
    function testCallback() {
        Common.callback();
    
        Assert.equals(2, Common.callbackSet, 'Bad cppia closure');
    }

    function testNewOfUnlinkedClass() {
        final source = sys.io.File.getBytes('bin/unlinked.cppia');

        Assert.raises(() -> cpp.cppia.Module.fromData(source.getData()), String, 'Linked a new of a class the host does not have');
    }

    @:depends(testStatus)
    function testStackObjectAfterScriptAllocations() {
        final nursery = Type.resolveClass('ClientNursery');
        Reflect.callMethod(nursery, Reflect.field(nursery, 'allocate'), []);
        // Only the stack references it, so only the nursery scan finds it.
        final kept = [42];

        Gc.run(false);
        final junk = [for (i in 0...100000) [i]];

        Assert.equals(42, kept[0]);
    }

    @:depends(testStatus)
    function testSetFieldOfOldObject() {
        final holder = Type.createInstance(Type.resolveClass('ClientHolder'), []);

        // Full collections make the holder old: a generational collection no longer traverses it.
        for (_ in 0...3) {
            Gc.run(true);
        }
        final values = setValues(holder);
        Gc.run(false);

        Assert.notNull(values.get(), 'Freed a value set by name on an old object');
    }

    // Only a weak reference to the value leaves this frame, so that the stack does not keep it.
    static function setValues(holder:Dynamic):WeakRef<Array<Int>> {
        final values = [42];
        Reflect.setField(holder, 'values', values);
        return new WeakRef(values);
    }

    @:depends(testStatus)
    function testModuleValuesCreatedWhenOld() {
        final values = Type.resolveClass('ClientModuleValues');

        // Full collections make the module old: a generational collection no longer traverses it.
        for (_ in 0...3) {
            Gc.run(true);
        }
        final created = createValues(values);
        Gc.run(false);

        for (value in created) {
            Assert.notNull(value.get(), 'Freed a value that the old module holds');
        }
    }

    // Only weak references to the values leave this frame, so that the stack does not keep them.
    static function createValues(values:Dynamic):Array<WeakRef<Dynamic>> {
        return [for (name in ['literal', 'assigned']) new WeakRef<Dynamic>(Reflect.callMethod(values, Reflect.field(values, name), []))];
    }

    @:depends(testStatus)
    function testBoolMemberStorage() {
        final cls = Type.resolveClass('ClientBoolField');

        if (Assert.notNull(cls, 'Unable to resolve ClientBoolField')) {
            final obj = Type.createInstance(cls, []);

            Assert.same(Type.ValueType.TBool, Type.typeof(Reflect.field(obj, 'flag')), 'Member Bool did not read back as a boolean');
            Assert.same(Type.ValueType.TBool, Type.typeof(Reflect.field(cls, 'staticFlag')), 'Static Bool did not read back as a boolean');
        }
    }

    function callConvert(name:String):Dynamic {
        final cls = Type.resolveClass('ClientJitConvert');

        if (!Assert.notNull(cls, 'Unable to resolve ClientJitConvert')) {
            return null;
        }

        return Reflect.callMethod(null, Reflect.field(cls, name), []);
    }

    @:depends(testStatus)
    function testSubtractionToString() {
        Assert.equals('1', callConvert('subtractToString'), 'Int subtraction into a string did not answer');
    }

    @:depends(testStatus)
    function testSubtractionToFloat() {
        Assert.floatEquals(2.5, callConvert('subtractToFloat'), 'Int subtraction into a float did not answer');
    }

    @:depends(testStatus)
    function testSubtractionToDynamic() {
        Assert.equals(5, callConvert('subtractToDynamic'), 'Int subtraction into a dynamic did not answer');
    }

    @:depends(testStatus)
    function testDynamicToString() {
        Assert.equals('hello!', callConvert('dynamicToString'), 'Dynamic into a string did not answer');
    }

    @:depends(testStatus)
    function testDynamicToFloat() {
        Assert.floatEquals(3.5, callConvert('dynamicToFloat'), 'Dynamic into a float did not answer');
    }

    @:depends(testStatus)
    function testDynamicToFloatInRegister() {
        Assert.floatEquals(3.0, callConvert('dynamicToFloatInRegister'), 'Dynamic into a float register did not answer');
    }

    @:depends(testStatus)
    function testInterfaceCalling() {
        final obj : IFoo = Type.createInstance(Type.resolveClass('ClientFoo'), []);

        if (Assert.notNull(obj, 'Unable to create client implementation')) {
            Assert.equals('foo', obj.baz());
        }
    }

#if (haxe >= version("4.3.6"))
    @:depends(testStatus)
    function testMultiLevelInheritance() {
        if (Assert.notNull(Common.clientRoot, 'Null client root class')) {
            if (Assert.equals(3, Common.clientRoot.values.length, 'Expected three items in the array')) {
                Assert.equals(0, Common.clientRoot.values[0]);
                Assert.equals(1, Common.clientRoot.values[1]);
                Assert.equals(2, Common.clientRoot.values[2]);
            }
        }
    }
#end
}