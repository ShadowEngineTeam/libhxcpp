function main() {
	var s:String = "5";
	var ts:String = "true";
	var five:Dynamic = 5;
	var yes:Dynamic = true;
	var d5:Dynamic = "5";
	var ab:Dynamic = "ab";
	var none:Dynamic = null;
	Sys.println(s == five);
	Sys.println(ts == yes);
	Sys.println(s != five);
	Sys.println(five == s);
	Sys.println(s == d5);
	Sys.println("aa" < ab);
	Sys.println(ab >= "ab");
	Sys.println(s == none);
	Sys.println(s < five || s > five);
}
