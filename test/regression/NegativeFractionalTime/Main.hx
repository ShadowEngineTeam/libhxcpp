function main() {
	var d = Date.fromTime(-500);
	Sys.println(d.getUTCFullYear() + " " + d.getUTCHours() + ":" + d.getUTCMinutes() + ":" + d.getUTCSeconds());
	Sys.println(Date.fromTime(-1500).getUTCSeconds());
	var local = Date.fromTime(-1500);
	var whole = Date.fromTime(-2000);
	Sys.println(local.getSeconds() == whole.getSeconds());
	Sys.println(Date.fromTime(1500).getUTCSeconds());
}
