function main() {
	// 2024-01-15 and 2024-07-15, 12:00 UTC: one in each half of the year
	for (t in [1705320000.0, 1721044800.0]) {
		var d = Date.fromTime(t * 1000);
		var wallClock = DateTools.makeUtc(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes(), d.getSeconds());
		Sys.println(d.getTimezoneOffset() == Std.int((d.getTime() - wallClock) / 60000));
	}
}
