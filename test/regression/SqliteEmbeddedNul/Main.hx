class Main {
	static function main() {
		var db = sys.db.Sqlite.open(":memory:");
		var sql = "SELECT CAST(x'4100c3a942' AS TEXT) AS value";
		var expected = "A\x00éB";
		var row = db.request(sql).next();
		var value:String = row.value;
		Sys.println("row text preserved: " + (value == expected));
		Sys.println("indexed text preserved: " + (db.request(sql).getResult(0) == expected));
		Sys.println("SQL NULL preserved: " + (db.request("SELECT NULL AS value").next().value == null));
		db.close();
	}
}
