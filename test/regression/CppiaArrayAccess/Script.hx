class Script {
	static function main() {
		var g = new Grid();
		g[1] = 5;
		g[1] += 2;
		g[2] = g[1]++;
		var pre = ++g[0];
		Sys.println(g[0] + " " + g[1] + " " + g[2] + " " + pre);
	}
}
