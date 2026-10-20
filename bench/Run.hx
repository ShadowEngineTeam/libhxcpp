package;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;

/**
	Compares libhxcpp with stock hxcpp on the benchmarks in bench/src.

	  cd bench
	  haxe --run Run [options]

	Each runtime gets its own directory in bench/.work with its own local
	haxelib repository, so the same Haxe sources are built once against
	this checkout and once against a stock hxcpp release, with the same
	Haxe, C++ compiler and flags. Benchmarks run one per process, and the
	runtimes take turns so that drift on the machine hits both alike.

	Options:
	  --stock <version>     stock hxcpp release to compare with (default 4.3.53,
	                        the release Lime's CI builds desktop and mobile with).
	                        Downloaded from the HaxeFoundation/hxcpp GitHub release
	                        and installed with haxelib, as Lime's CI does; haxelib's
	                        own registry stops at 4.3.2.
	  --stock-dev <path>    use a stock hxcpp checkout instead of a release
	  --runtimes <list>     libhxcpp,stock (default both)
	  --only <list>         benchmark names, comma-separated
	  --runs <n>            processes per benchmark and runtime (default 3)
	  --samples <n>         timed samples per process (default 10)
	  --warmup <n>          untimed samples per process (default 2)
	  --no-build            reuse the existing builds
	  --out <file>          results JSON (default .work/results.json)
	  --readme              also write the tables into README.md

	Exits non-zero if any build fails, any process fails, or two runs of a
	benchmark disagree on the checksum, which means one did different work.
**/
class Run {
	static inline var STARTUP_RUNS = 20;
	static inline var README_START = "<!-- bench:start -->";
	static inline var README_END = "<!-- bench:end -->";

	static var benchDir:String;
	static var rootDir:String;
	static var workDir:String;

	static var stockVersion = "4.3.53";
	static var stockDev:Null<String> = null;
	static var runtimeNames = ["libhxcpp", "stock"];
	static var only:Null<Array<String>> = null;
	static var runs = 3;
	static var samples = 10;
	static var warmup = 2;
	static var build = true;
	static var outFile:Null<String> = null;
	static var writeReadme = false;

	static function main() {
		benchDir = FileSystem.absolutePath(".");
		if (!FileSystem.exists(benchDir + "/src/Main.hx"))
			fail("run this from the bench directory: cd bench && haxe --run Run");
		rootDir = FileSystem.absolutePath("..");
		workDir = benchDir + "/.work";
		parseArgs(Sys.args());
		if (outFile == null)
			outFile = workDir + "/results.json";

		var runtimes = [for (name in runtimeNames) new Runtime(name, label(name), workDir + "/" + name)];
		for (rt in runtimes) {
			if (build) {
				prepareRepo(rt);
				buildRuntime(rt);
			}
			if (!FileSystem.exists(rt.exe))
				fail('${rt.label}: ${rt.exe} is missing; run without --no-build');
			rt.env = readEnv(rt);
			Sys.println('${rt.label}: ${rt.env.compiler}, ${rt.env.pointerBits}-bit, API level ${rt.env.apiLevel}');
		}
		checkComparable(runtimes);

		var names = listBenchmarks(runtimes[0]);
		if (only != null) {
			for (n in only)
				if (names.indexOf(n) < 0)
					fail('unknown benchmark $n');
			names = only;
		}

		var failures = 0;
		var startup = measureStartup(runtimes);
		var results:Array<BenchResult> = [];
		for (name in names) {
			Sys.print('$name ');
			var r = runBenchmark(name, runtimes);
			if (r.error != null) {
				failures++;
				Sys.println('FAILED: ${r.error}');
			} else
				Sys.println([for (rt in runtimes) '${rt.label} ${formatRate(r.byRuntime.get(rt.name).rate, r.unit)}'].join(", "));
			results.push(r);
		}

		var report = {
			date: Date.now().toString(),
			host: hostInfo(),
			haxe: commandOutput("haxe", ["-version"]),
			libhxcpp: gitDescribe(),
			runtimes: [for (rt in runtimes) {name: rt.name, label: rt.label, env: rt.env}],
			settings: {runs: runs, samples: samples, warmup: warmup},
			startup: [for (rt in runtimes) {name: rt.name, seconds: startup[rt.name]}],
			benchmarks: [for (r in results) r.toJson()],
		};
		File.saveContent(outFile, Json.stringify(report, null, "  "));
		Sys.println('\nResults: $outFile\n');

		var tables = markdown(report, runtimes, startup, results);
		Sys.println(tables);
		if (writeReadme)
			updateReadme(tables);

		if (failures > 0) {
			Sys.println('$failures benchmark(s) failed');
			Sys.exit(1);
		}
	}

	static function parseArgs(args:Array<String>) {
		var i = 0;
		function value():String {
			if (i + 1 >= args.length)
				fail('${args[i]} needs a value');
			return args[++i];
		}
		function count():Int {
			var name = args[i];
			var n = Std.parseInt(value());
			if (n == null || n < 1)
				fail('$name needs a positive number');
			return n;
		}
		while (i < args.length) {
			switch (args[i]) {
				case "--stock":
					stockVersion = value();
				case "--stock-dev":
					stockDev = FileSystem.absolutePath(value());
				case "--runtimes":
					runtimeNames = value().split(",");
					for (n in runtimeNames)
						if (n != "libhxcpp" && n != "stock")
							fail('unknown runtime $n');
				case "--only":
					only = value().split(",");
				case "--runs":
					runs = count();
				case "--samples":
					samples = count();
				case "--warmup":
					var n = Std.parseInt(value());
					if (n == null || n < 0)
						fail("--warmup needs a number");
					warmup = n;
				case "--no-build":
					build = false;
				case "--out":
					outFile = FileSystem.absolutePath(value());
				case "--readme":
					writeReadme = true;
				default:
					fail('unknown option ${args[i]}');
			}
			i++;
		}
	}

	static function label(name:String):String {
		if (name == "libhxcpp")
			return "libhxcpp";
		return stockDev != null ? "hxcpp (dev)" : 'hxcpp $stockVersion';
	}

	// --- Building --------------------------------------------------------

	/** Gives the runtime directory its own .haxelib, holding only the hxcpp under test. **/
	static function prepareRepo(rt:Runtime) {
		FileSystem.createDirectory(rt.dir);
		inDir(rt.dir, () -> {
			if (!FileSystem.exists(rt.dir + "/.haxelib"))
				run("haxelib", ["newrepo"]);
			if (rt.name == "libhxcpp")
				run("haxelib", ["dev", "hxcpp", rootDir]);
			else if (stockDev != null)
				run("haxelib", ["dev", "hxcpp", stockDev]);
			else {
				run("haxelib", ["install", downloadStock(), "--always", "--quiet"]);
				run("haxelib", ["set", "hxcpp", stockVersion, "--always"]);
			}
			// Make sure Haxe will pick up the intended hxcpp before spending minutes building
			var out = commandOutput("haxelib", ["path", "hxcpp"]);
			var lines = [for (l in out.split("\n")) if (l.trim() != "" && !l.startsWith("-")) l.trim()];
			var path = lines.length > 0 ? lines[0] : "";
			var expected = rt.name == "libhxcpp" ? rootDir : (stockDev != null ? stockDev : rt.dir + "/.haxelib/hxcpp/" + stockVersion.replace(".", ","));
			if (path == "" || normalize(path).indexOf(normalize(expected)) != 0)
				fail('${rt.label}: haxelib resolves hxcpp to "$path", expected $expected\n$out');
			rt.hxcppPath = path;
		});
	}

	/**
		Downloads the stock release zip from GitHub, the same file Lime's CI
		installs, and returns its path. Kept in .work/downloads between runs.
	**/
	static function downloadStock():String {
		var dir = workDir + "/downloads";
		FileSystem.createDirectory(dir);
		var zip = '$dir/hxcpp-$stockVersion.zip';
		if (!FileSystem.exists(zip)) {
			var url = 'https://github.com/HaxeFoundation/hxcpp/releases/download/v$stockVersion/hxcpp-$stockVersion.zip';
			Sys.println('Downloading $url');
			var code = Sys.command("curl", ["--fail", "--location", "--silent", "--show-error", "--output", zip + ".part", url]);
			if (code != 0) {
				if (FileSystem.exists(zip + ".part"))
					FileSystem.deleteFile(zip + ".part");
				fail('could not download hxcpp $stockVersion from $url (curl exit code $code)');
			}
			FileSystem.rename(zip + ".part", zip);
		}
		return zip;
	}

	static function buildRuntime(rt:Runtime) {
		Sys.println('Building ${rt.label} (log: ${rt.dir}/build.log)');
		// Stock hxcpp builds 32-bit by default on Windows and libhxcpp builds 64-bit,
		// so ask both for 64-bit. Elsewhere both already default to the host word size.
		var flags = Sys.systemName() == "Windows" ? " -D HXCPP_M64" : "";
		var code = inDir(rt.dir, () -> Sys.command('haxe -cp "${benchDir}/src" -main Main -cpp out$flags > build.log 2>&1'));
		if (code != 0) {
			var log = File.getContent(rt.dir + "/build.log").split("\n");
			Sys.println(log.slice(log.length > 40 ? log.length - 40 : 0).join("\n"));
			fail('${rt.label}: build failed');
		}
	}

	static function readEnv(rt:Runtime):Dynamic {
		var out = benchProcess(rt, ["env"]);
		for (line in out.split("\n"))
			if (line.startsWith("BENCH_ENV "))
				return Json.parse(line.substr(10));
		return fail('${rt.label}: no BENCH_ENV line');
	}

	/** The comparison only means something if both builds used the same compiler and word size. **/
	static function checkComparable(runtimes:Array<Runtime>) {
		for (rt in runtimes) {
			var first = runtimes[0];
			if (rt.env.compiler != first.env.compiler)
				fail('compilers differ: ${first.label} used ${first.env.compiler}, ${rt.label} used ${rt.env.compiler}');
			if (rt.env.pointerBits != first.env.pointerBits)
				fail('word sizes differ: ${first.env.pointerBits}-bit and ${rt.env.pointerBits}-bit');
		}
	}

	static function listBenchmarks(rt:Runtime):Array<String> {
		return [for (l in benchProcess(rt, ["list"]).split("\n")) if (l.trim() != "") l.trim()];
	}

	// --- Measuring -------------------------------------------------------

	/** Median wall-clock time to start and exit the program, in seconds. **/
	static function measureStartup(runtimes:Array<Runtime>):Map<String, Float> {
		var times = [for (rt in runtimes) rt.name => new Array<Float>()];
		for (i in 0...STARTUP_RUNS)
			for (k in 0...runtimes.length) {
				var rt = runtimes[(i + k) % runtimes.length];
				var t0 = Sys.time();
				var p = new Process(rt.exe, ["noop"]);
				var code = p.exitCode();
				p.close();
				if (code != 0)
					fail('${rt.label}: noop exited with $code');
				times[rt.name].push(Sys.time() - t0);
			}
		return [for (rt in runtimes) rt.name => median(times[rt.name])];
	}

	static function runBenchmark(name:String, runtimes:Array<Runtime>):BenchResult {
		var result = new BenchResult(name);
		var raw = [for (rt in runtimes) rt.name => new Array<Dynamic>()];
		var checksum:Null<Int> = null;
		var checksumFrom = "";
		for (i in 0...runs)
			for (k in 0...runtimes.length) {
				// Alternate who goes first, so neither always runs on a cooler or warmer machine
				var rt = runtimes[(i + k) % runtimes.length];
				var out = try benchProcess(rt, [name, "--warmup", '$warmup', "--samples", '$samples']) catch (e:Dynamic) {
					result.error = '${rt.label}: $e';
					return result;
				}
				var json:Dynamic = null;
				for (line in out.split("\n"))
					if (line.startsWith("BENCH_RESULT "))
						json = Json.parse(line.substr(13));
				if (json == null) {
					result.error = '${rt.label}: no BENCH_RESULT line';
					return result;
				}
				if (checksum == null) {
					checksum = json.checksum;
					checksumFrom = rt.label;
				} else if (json.checksum != checksum) {
					result.error = 'checksum ${json.checksum} from ${rt.label} differs from $checksum from $checksumFrom';
					return result;
				}
				raw[rt.name].push(json);
			}

		for (rt in runtimes) {
			var list = raw[rt.name];
			var first:Dynamic = list[0];
			result.unit = first.unit;
			var times:Array<Float> = [];
			var rss:Array<Float> = [];
			var p50:Array<Float> = [];
			var p99:Array<Float> = [];
			var p999:Array<Float> = [];
			var max:Array<Float> = [];
			for (j in list) {
				for (t in (j.times : Array<Float>))
					times.push(t);
				rss.push(j.peakRss);
				if (j.latency != null) {
					p50.push(j.latency.p50);
					p99.push(j.latency.p99);
					p999.push(j.latency.p999);
					max.push(j.latency.max);
				}
			}
			var t = median(times);
			var m = new Measurement();
			m.rate = first.ops / t;
			m.spread = mad(times) / t;
			m.peakRss = median(rss);
			if (p50.length > 0)
				m.latency = {
					p50: median(p50),
					p99: median(p99),
					p999: median(p999),
					max: median(max)
				};
			m.raw = list;
			result.byRuntime.set(rt.name, m);
		}
		result.checksum = checksum;
		return result;
	}

	// --- Reporting -------------------------------------------------------

	static function markdown(report:Dynamic, runtimes:Array<Runtime>, startup:Map<String, Float>, results:Array<BenchResult>):String {
		var lib = runtimes.filter(rt -> rt.name == "libhxcpp")[0];
		var stock = runtimes.filter(rt -> rt.name == "stock")[0];
		var b = new StringBuf();
		var cols = [for (rt in runtimes) rt.label];
		var compare = lib != null && stock != null;

		function header(first:Array<String>, extra:Array<String>) {
			var all = first.concat(cols).concat(compare ? extra : []);
			b.add("| " + all.join(" | ") + " |\n");
			b.add("|" + [for (i in 0...all.length) i < first.length ? " --- " : " ---: "].join("|") + "|\n");
		}

		b.add("**Speed** (higher is better)\n\n");
		header(["Benchmark", "Unit"], ["libhxcpp vs stock"]);
		for (r in results) {
			if (r.error != null) {
				b.add('| ${r.name} | | ' + [for (rt in runtimes) "failed"].join(" | ") + (compare ? " | |" : "") + "\n");
				continue;
			}
			var cells = [for (rt in runtimes) formatRate(r.byRuntime.get(rt.name).rate, null) + " ±" + percent(r.byRuntime.get(rt.name).spread)];
			var row = '| ${r.name} | ${r.unit}/s | ' + cells.join(" | ");
			if (compare)
				row += " | " + ratio(r.byRuntime.get(lib.name).rate, r.byRuntime.get(stock.name).rate,
					Math.max(r.byRuntime.get(lib.name).spread, r.byRuntime.get(stock.name).spread));
			b.add(row + " |\n");
		}

		b.add("\n**Collection pauses and memory** (lower is better)\n\n");
		header(["Metric", "Benchmark"], ["stock / libhxcpp"]);
		function lowerRow(metric:String, bench:String, values:Map<String, Float>, format:Float->String) {
			var row = '| $metric | $bench | ' + [for (rt in runtimes) format(values[rt.name])].join(" | ");
			if (compare)
				row += " | " + ratio(values[stock.name], values[lib.name], 0);
			b.add(row + " |\n");
		}
		lowerRow("Startup and exit", "noop", startup, ms);
		for (r in results)
			if (r.error == null && r.byRuntime.get(runtimes[0].name).latency != null) {
				for (p in ["p99", "p999", "max"])
					lowerRow('Work unit time, ${p == "p999" ? "p99.9" : p}', r.name,
						[for (rt in runtimes) rt.name => Reflect.field(r.byRuntime.get(rt.name).latency, p)], ms);
			}
		for (r in results)
			if (r.error == null)
				lowerRow("Peak memory", r.name, [for (rt in runtimes) rt.name => r.byRuntime.get(rt.name).peakRss], mb);

		var env = runtimes[0].env;
		b.add('\n${report.host}; ${env.compiler}, ${env.pointerBits}-bit; ${report.haxe}; '
			+ 'libhxcpp ${report.libhxcpp}; ${runs} processes x ${samples} samples per benchmark; ${report.date}.\n');
		b.add("Reproduce with `cd bench && haxe --run Run`. Ratios above 1 favour libhxcpp; "
			+ "\"~\" marks a difference within the run-to-run spread.\n");
		return b.toString();
	}

	static function updateReadme(tables:String) {
		var path = rootDir + "/README.md";
		var text = File.getContent(path);
		var start = text.indexOf(README_START);
		var end = text.indexOf(README_END);
		if (start < 0 || end < start)
			fail('README.md has no $README_START ... $README_END block');
		File.saveContent(path, text.substr(0, start + README_START.length) + "\n" + tables + text.substr(end));
		Sys.println("README.md updated");
	}

	static function ratio(better:Float, worse:Float, spread:Float):String {
		var r = better / worse;
		var s = Std.string(Math.round(r * 100) / 100);
		if (s.indexOf(".") < 0)
			s += ".0";
		return (Math.abs(r - 1) <= spread * 2 ? "~" : "") + s + "x";
	}

	static function formatRate(rate:Float, unit:Null<String>):String {
		var s = rate >= 1e9 ? round(rate / 1e9) + "G" : rate >= 1e6 ? round(rate / 1e6) + "M" : rate >= 1e3 ? round(rate / 1e3) + "k" : round(rate);
		return unit == null ? s : '$s $unit/s';
	}

	static function round(v:Float):String {
		return Std.string(v >= 100 ? Math.round(v) : Math.round(v * 10) / 10);
	}

	static function percent(v:Float):String {
		return round(v * 100) + "%";
	}

	static function ms(seconds:Float):String {
		return seconds < 0.001 ? round(seconds * 1e6) + " us" : round(seconds * 1000) + " ms";
	}

	static function mb(bytes:Float):String {
		return bytes < 0 ? "n/a" : round(bytes / (1024 * 1024)) + " MB";
	}

	static function median(values:Array<Float>):Float {
		var s = values.copy();
		s.sort(Reflect.compare);
		var n = s.length;
		return n == 0 ? Math.NaN : (n & 1) == 1 ? s[n >> 1] : (s[(n >> 1) - 1] + s[n >> 1]) / 2;
	}

	/** Median absolute deviation. **/
	static function mad(values:Array<Float>):Float {
		var m = median(values);
		return median([for (v in values) Math.abs(v - m)]);
	}

	// --- Environment -----------------------------------------------------

	static function hostInfo():String {
		var cpu = Sys.getEnv("PROCESSOR_IDENTIFIER");
		if (Sys.systemName() == "Windows") {
			var name = commandOutput("powershell", ["-NoProfile", "-Command", "(Get-CimInstance Win32_Processor).Name"]);
			if (name != "")
				cpu = name;
		} else if (FileSystem.exists("/proc/cpuinfo")) {
			for (line in File.getContent("/proc/cpuinfo").split("\n"))
				if (line.startsWith("model name")) {
					cpu = line.substr(line.indexOf(":") + 1).trim();
					break;
				}
		} else if (Sys.systemName() == "Mac")
			cpu = commandOutput("sysctl", ["-n", "machdep.cpu.brand_string"]);
		return '${Sys.systemName()}, ${cpu == null ? "unknown CPU" : cpu.trim()}';
	}

	static function gitDescribe():String {
		var commit = inDir(rootDir, () -> commandOutput("git", ["rev-parse", "--short", "HEAD"]));
		var dirty = inDir(rootDir, () -> commandOutput("git", ["status", "--porcelain", "--untracked-files=no"]));
		return commit + (dirty != "" ? " (modified)" : "");
	}

	// --- Processes -------------------------------------------------------

	/** Runs the benchmark executable and returns its stdout; throws if it fails. **/
	static function benchProcess(rt:Runtime, args:Array<String>):String {
		var p = new Process(rt.exe, args);
		var out = p.stdout.readAll().toString();
		var err = p.stderr.readAll().toString();
		var code = p.exitCode();
		p.close();
		if (code != 0)
			throw 'exit code $code\n$err';
		return out.replace("\r", "");
	}

	static function commandOutput(cmd:String, args:Array<String>):String {
		try {
			var p = new Process(cmd, args);
			var out = p.stdout.readAll().toString();
			p.stderr.readAll();
			p.exitCode();
			p.close();
			return out.replace("\r", "").trim();
		} catch (e:Dynamic) {
			return "";
		}
	}

	static function run(cmd:String, args:Array<String>) {
		var code = Sys.command(cmd, args);
		if (code != 0)
			fail('$cmd ${args.join(" ")} failed with exit code $code');
	}

	static function inDir<T>(dir:String, f:() -> T):T {
		var old = Sys.getCwd();
		Sys.setCwd(dir);
		try {
			var r = f();
			Sys.setCwd(old);
			return r;
		} catch (e:Dynamic) {
			Sys.setCwd(old);
			throw e;
		}
	}

	static function normalize(path:String):String {
		return path.replace("\\", "/").toLowerCase();
	}

	static function fail(message:String):Dynamic {
		Sys.stderr().writeString("error: " + message + "\n");
		Sys.exit(1);
		return null;
	}
}

class Runtime {
	public final name:String;
	public final label:String;
	public final dir:String;
	public final exe:String;
	public var hxcppPath = "";
	public var env:Dynamic = null;

	public function new(name:String, label:String, dir:String) {
		this.name = name;
		this.label = label;
		this.dir = dir;
		this.exe = dir + "/out/Main" + (Sys.systemName() == "Windows" ? ".exe" : "");
	}
}

class Measurement {
	public var rate = 0.0;
	public var spread = 0.0;
	public var peakRss = 0.0;
	public var latency:Null<{p50:Float, p99:Float, p999:Float, max:Float}> = null;
	public var raw:Array<Dynamic> = [];

	public function new() {}
}

class BenchResult {
	public final name:String;
	public var unit = "";
	public var checksum:Null<Int> = null;
	public var error:Null<String> = null;
	public final byRuntime = new Map<String, Measurement>();

	public function new(name:String) {
		this.name = name;
	}

	public function toJson():Dynamic {
		var runtimes = {};
		for (name => m in byRuntime)
			Reflect.setField(runtimes, name, {
				rate: m.rate,
				spread: m.spread,
				peakRss: m.peakRss,
				latency: m.latency,
				processes: m.raw,
			});
		return {
			name: name,
			unit: unit,
			checksum: checksum,
			error: error,
			runtimes: runtimes
		};
	}
}
