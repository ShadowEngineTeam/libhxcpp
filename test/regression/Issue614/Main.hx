typedef TestDef = {
	@:optional var floatField:Float;
}

typedef TestDef2 = {
	@:optional var multiplied:Float;
}

function main() {
	var testDef:TestDef = {floatField: 50000000};
	var def:TestDef2 = {multiplied: testDef.floatField * 400};
	Sys.println(def.multiplied > 0);
	Sys.println(def.multiplied);
}
