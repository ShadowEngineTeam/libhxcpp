@:cppFileCode('
static bool auditPermanentName(String value) {
	const unsigned char *data = (const unsigned char *)value.raw_ref();
	return data && (data[HX_GC_CONST_ALLOC_MARK_OFFSET] & HX_GC_CONST_ALLOC_MARK_BIT);
}
')
class Main {
	static function main() {
		var db = sys.db.Sqlite.open(":memory:");
		var name = "query_column_" + Std.string(Date.now().getTime());
		var row = db.request('SELECT 42 AS "$name"').next();
		var field = Reflect.fields(row)[0];
		Sys.println("column name preserved: " + (field == name));
		var permanent:Bool = untyped __cpp__("auditPermanentName({0})", field);
		Sys.println("dynamic column name is collectable: " + !permanent);
		db.close();
		for (i in 0...3) cpp.vm.Gc.run(true);
		Sys.println("row survives close and collection: " + (Reflect.field(row, field) == 42));
	}
}
