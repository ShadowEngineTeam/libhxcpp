package;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
	Reports how one runtime's results differ from another's in a results
	file from Run.hx: throughput, tail pauses and peak memory, each judged
	against its own noise. CI runs it on a change against its base commit.

	  cd bench
	  haxe --run Run --base <checkout> --out results.json
	  haxe --run Compare results.json [options]

	Options:
	  --new <runtime>       the runtime being checked (default libhxcpp)
	  --old <runtime>       the runtime it is compared with (default base)
	  --summary <file>      append the Markdown report to this file, such as
	                        $GITHUB_STEP_SUMMARY, as well as printing it
	  --github              print a GitHub Actions warning for each regression
	  --fail-on-regression  exit with 1 when anything regressed past its noise
	  --history <file>      append one JSON line with the new runtime's numbers
	                        and its ratios to the old one, for trends over time

	A difference only counts past its noise: twice the larger run-to-run
	spread of the two runtimes (the median absolute deviation over the
	median, as Run.hx's tables use), and never less than a floor for the
	measure. Ratios above 1 favour the new runtime, as in BENCHMARKS.md.

	Exits with 1 only for a results file it cannot read, or with
	--fail-on-regression; a missing old runtime, such as a base that could
	not build these benchmarks, is reported and is not a failure.
**/
class Compare {
	/**
		The noise floor for tail pauses. Two builds of the same commit, run
		together on a busy 16-core Windows machine, measured gc_pauses p99.9
		work unit times 3% apart, but a single collection more or less moves
		a tail, and shared runners are noisier. The scheduled A/A runs record
		what the runners actually do, so this can be narrowed from that.
	**/
	static inline var PAUSE_BAND = 0.25;

	/**
		The noise floor for peak memory. The same two builds measured every
		benchmark's peak working set within 1% of each other; a collection
		starting at a slightly different point can still move it further.
	**/
	static inline var MEMORY_BAND = 0.05;

	static var newName = "libhxcpp";
	static var oldName = "base";
	static var summaryFile:Null<String> = null;
	static var historyFile:Null<String> = null;
	static var github = false;
	static var failOnRegression = false;

	static function main() {
		var file:Null<String> = null;
		var args = Sys.args();
		var i = 0;
		function value():String {
			if (i + 1 >= args.length)
				fail('${args[i]} needs a value');
			return args[++i];
		}
		while (i < args.length) {
			switch (args[i]) {
				case "--new":
					newName = value();
				case "--old":
					oldName = value();
				case "--summary":
					summaryFile = value();
				case "--history":
					historyFile = value();
				case "--github":
					github = true;
				case "--fail-on-regression":
					failOnRegression = true;
				case a if (a.startsWith("--")):
					fail('unknown option $a');
				case a:
					file = a;
			}
			i++;
		}
		if (file == null)
			fail("usage: haxe --run Compare <results.json> [--new libhxcpp] [--old base] [--summary file] [--github] [--fail-on-regression] [--history file]");
		if (!FileSystem.exists(file))
			fail('$file does not exist');
		var report:Dynamic = Json.parse(File.getContent(file));

		var runtimes:Array<Dynamic> = report.runtimes;
		var newRt = runtimes.filter(r -> r.name == newName)[0];
		var oldRt = runtimes.filter(r -> r.name == oldName)[0];
		if (newRt == null)
			fail('$file has no results for $newName');

		var b = new StringBuf();
		var regressions:Array<String> = [];
		var history:Dynamic = {
			date: report.date,
			host: report.host,
			compiler: newRt.env.compiler,
			pointerBits: newRt.env.pointerBits,
			haxe: report.haxe,
			commit: newRt.commit,
			settings: report.settings,
			benchmarks: {},
		};

		if (oldRt == null) {
			var skipped:Array<Dynamic> = report.skipped == null ? [] : report.skipped;
			var why = [for (s in skipped) if (s.name == oldName) s.reason];
			b.add('### Benchmarks: ${newRt.label}\n\nNo comparison: $oldName ${why.length > 0 ? why[0] : "has no results"}.\n');
		} else {
			b.add('### Benchmarks: ${newRt.label} vs ${oldRt.label}\n\n');
			Reflect.setField(history, "vs", {runtime: oldName, commit: oldRt.commit});
		}

		var benchmarks:Array<Dynamic> = report.benchmarks;
		var speed:Array<Row> = [];
		var pauses:Array<Row> = [];
		var memory:Array<Row> = [];
		var failed:Array<String> = [];
		for (bench in benchmarks) {
			var n:Dynamic = bench.error == null ? Reflect.field(bench.runtimes, newName) : null;
			if (n == null) {
				failed.push(bench.name);
				continue;
			}
			var o:Dynamic = oldRt == null ? null : Reflect.field(bench.runtimes, oldName);
			var nProcs:Array<Dynamic> = n.processes;
			var oProcs:Array<Dynamic> = o == null ? [] : o.processes;

			var entry:Dynamic = {rate: n.rate, spread: n.spread, peakRss: n.peakRss};
			Reflect.setField(history.benchmarks, bench.name, entry);

			speed.push(new Row(bench.name, bench.unit + "/s", n.rate, n.spread, o == null ? null : o.rate, o == null ? 0 : o.spread, true,
				Run.LAYOUT_BAND));
			if (n.latency != null) {
				var np = perProcess(nProcs, p -> p.latency.p999);
				entry.p999 = np.value;
				var op = o == null ? null : perProcess(oProcs, p -> p.latency.p999);
				pauses.push(new Row(bench.name, "p99.9", np.value, np.spread, op == null ? null : op.value, op == null ? 0 : op.spread, false,
					PAUSE_BAND));
			}
			var nm = perProcess(nProcs, p -> p.peakRss);
			var om = o == null ? null : perProcess(oProcs, p -> p.peakRss);
			if (nm.value > 0 && (om == null || om.value > 0))
				memory.push(new Row(bench.name, "peak", nm.value, nm.spread, om == null ? null : om.value, om == null ? 0 : om.spread, false,
					MEMORY_BAND));
		}

		var sections = [
			{title: "Throughput", what: "speed", rows: speed, format: (v:Float) -> Run.formatRate(v, null)},
			{title: "Tail pauses", what: "p99.9 work unit time", rows: pauses, format: Run.ms},
			{title: "Peak memory", what: "peak memory", rows: memory, format: Run.mb},
		];
		if (oldRt != null) {
			var improved = 0;
			for (s in sections)
				for (r in s.rows) {
					if (r.verdict() == "regressed")
						regressions.push('${r.name} ${s.what}: ${Run.ratioText(r.ratio())}, noise ±${Run.percent(r.noise())}');
					else if (r.verdict() == "improved")
						improved++;
				}
			b.add('${regressions.length} regression${regressions.length == 1 ? "" : "s"} and $improved improvement${improved == 1 ? "" : "s"} past the noise.\n');
		}
		if (failed.length > 0)
			b.add('\nFailed: ${failed.join(", ")}\n');

		for (s in sections) {
			if (s.rows.length == 0)
				continue;
			b.add('\n**${s.title}**' + (oldRt == null ? "\n\n" : ' (ratios above 1 favour ${newName})\n\n'));
			if (oldRt == null) {
				b.add('| Benchmark | ${newRt.label} |\n| --- | ---: |\n');
				for (r in s.rows)
					b.add('| ${r.name} | ${s.format(r.newValue)} ±${Run.percent(r.newSpread)} |\n');
				continue;
			}
			b.add('| Benchmark | ${oldRt.label} | ${newRt.label} | Ratio | Noise | |\n| --- | ---: | ---: | ---: | ---: | --- |\n');
			for (r in s.rows) {
				if (r.oldValue == null) {
					b.add('| ${r.name} | | ${s.format(r.newValue)} | | | new |\n');
					continue;
				}
				var ratio = r.ratio();
				Reflect.setField(Reflect.field(history.benchmarks, r.name), s == sections[0] ? "speedRatio" : s == sections[1] ? "p999Ratio" : "memoryRatio",
					Math.round(ratio * 1000) / 1000);
				b.add('| ${r.name} | ${s.format(r.oldValue)} | ${s.format(r.newValue)} | ${Run.ratioText(ratio)} | ±${Run.percent(r.noise())} | ${r.verdict()} |\n');
			}
		}

		var settings:Dynamic = report.settings;
		b.add('\n${report.host}; ${newRt.env.compiler}, ${newRt.env.pointerBits}-bit; Haxe ${report.haxe}; '
			+ '${settings.runs} processes x ${settings.samples} samples per benchmark; ${report.date}. '
			+ 'Noise is twice the larger run-to-run spread, and at least ${Run.percent(Run.LAYOUT_BAND)} for speed, '
			+ '${Run.percent(PAUSE_BAND)} for pauses and ${Run.percent(MEMORY_BAND)} for memory.\n');

		var text = b.toString();
		Sys.println(text);
		if (summaryFile != null)
			append(summaryFile, text + "\n");
		if (historyFile != null)
			append(historyFile, Json.stringify(history) + "\n");
		if (github)
			for (r in regressions)
				Sys.println('::warning title=Benchmark regression::$r');
		if (failOnRegression && regressions.length > 0)
			Sys.exit(1);
	}

	/** The median over processes of one number each process reported, and its relative spread. **/
	static function perProcess(procs:Array<Dynamic>, get:Dynamic->Float):{value:Float, spread:Float} {
		var values = [for (p in procs) get(p)];
		var m = Run.median(values);
		return {value: m, spread: m > 0 ? Run.mad(values) / m : 0};
	}

	static function append(path:String, text:String) {
		var out = File.append(path, false);
		out.writeString(text);
		out.close();
	}

	static function fail(message:String):Dynamic {
		Sys.stderr().writeString("error: " + message + "\n");
		Sys.exit(1);
		return null;
	}
}

private class Row {
	public final name:String;
	public final measure:String;
	public final newValue:Float;
	public final newSpread:Float;
	public final oldValue:Null<Float>;
	public final oldSpread:Float;

	/** Whether a bigger value is better: true for speed, false for times and sizes. **/
	public final higherIsBetter:Bool;

	public final floor:Float;

	public function new(name, measure, newValue, newSpread, oldValue, oldSpread, higherIsBetter, floor) {
		this.name = name;
		this.measure = measure;
		this.newValue = newValue;
		this.newSpread = newSpread;
		this.oldValue = oldValue;
		this.oldSpread = oldSpread;
		this.higherIsBetter = higherIsBetter;
		this.floor = floor;
	}

	/** Above 1 favours the new runtime. **/
	public function ratio():Float {
		return higherIsBetter ? newValue / oldValue : oldValue / newValue;
	}

	public function noise():Float {
		return Math.max(2 * Math.max(newSpread, oldSpread), floor);
	}

	public function verdict():String {
		if (oldValue == null || oldValue <= 0 || newValue <= 0)
			return "";
		var r = ratio();
		return r < 1 - noise() ? "regressed" : r > 1 + noise() ? "improved" : "";
	}
}
