import sys.db.Connection;

function claim(name:String, value:Bool)
	Sys.println(name + ": " + value);

// The message a request fails with, or null when it does not
function failure(cnx:Connection, sql:String):Null<String> {
	try {
		cnx.request(sql);
	} catch (e:Dynamic) {
		return Std.string(e);
	}
	return null;
}

function closes(cnx:Connection):Bool {
	try {
		cnx.close();
	} catch (e:Dynamic) {
		Sys.stderr().writeString('close: $e\n');
		return false;
	}
	return true;
}

function main() {
	var cnx = sys.db.Sqlite.open(":memory:");
	var message = failure(cnx, "SELECT 1 AS a, 2 AS a");
	claim("a column name used twice is refused", message != null && message.indexOf("same field is two times") >= 0);
	claim("the connection still runs requests", cnx.request("SELECT 3 AS b").next().b == 3);
	claim("the connection closes after the refused request", closes(cnx));

	cnx = sys.db.Sqlite.open(":memory:");
	cnx.request("CREATE TABLE t1 (id INTEGER, x TEXT)");
	cnx.request("CREATE TABLE t2 (id INTEGER, y TEXT)");
	var last = cnx.request("SELECT id FROM t1");
	message = failure(cnx, "SELECT * FROM t1, t2");
	claim("a join repeating a column name is refused", message != null && message.indexOf("same field is two times") >= 0);
	claim("the result before it still reads", last.length == 0);
	claim("the connection closes after the refused join", closes(cnx));
}
