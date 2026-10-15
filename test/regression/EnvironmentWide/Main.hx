function main() {
	var value = "caf\u00E9 \u65E5\u672C";
	Sys.putEnv("HXCPP_ENV_WIDE", value);
	var env = Sys.environment();
	Sys.println(Sys.getEnv("HXCPP_ENV_WIDE") == value);
	Sys.println(env.get("HXCPP_ENV_WIDE") == value);
	Sys.println(env.exists("PATH") || env.exists("Path"));
	Sys.println([for (k in env.keys()) if (k == "" || k.charAt(0) == "=") k].length);
}
