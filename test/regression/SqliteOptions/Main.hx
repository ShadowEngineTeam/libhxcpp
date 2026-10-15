function main() {
	final db = sys.db.Sqlite.open(":memory:");
	db.request("CREATE VIRTUAL TABLE docs USING fts5(body)");
	db.request("INSERT INTO docs VALUES ('the quick brown fox'), ('lazy dogs')");
	Sys.println("fts5 " + db.request("SELECT body FROM docs WHERE docs MATCH 'fox'").getResult(0));
	Sys.println("json " + db.request("SELECT json_extract('{\"a\":[1,2]}', '$.a[1]')").getIntResult(0));
	db.close();
}
