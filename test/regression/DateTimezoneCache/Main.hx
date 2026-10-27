// The local fields of the last time converted are cached per thread, keyed by
// the time alone, so a date read before a change of zone kept the old zone's
// fields until another time was converted (libhxcpp #392)
@:cppFileCode('
#include <stdlib.h>
#include <time.h>
static void nativeSetZone(String zone) {
#ifdef HX_WINDOWS
	_putenv_s("TZ", zone.utf8_str());
	_tzset();
#else
	setenv("TZ", zone.utf8_str(), 1);
	tzset();
#endif
}
static int uncachedLocalHour(double seconds) {
	time_t time = (time_t)seconds;
	struct tm value;
#ifdef HX_WINDOWS
	localtime_s(&value, &time);
#else
	localtime_r(&time, &value);
#endif
	return value.tm_hour;
}
')
class Main {
	static function main() {
		var old = Sys.getEnv("TZ");
		var midnight = 1609459200.0; // 2021-01-01 00:00 UTC

		Sys.putEnv("TZ", "UTC0");
		var date = Date.fromTime(midnight * 1000);
		var utc = date.getHours();

		// A native extension that changes the zone itself
		untyped __cpp__("nativeSetZone({0})", "EST5");
		var nativeHour:Int = untyped __cpp__("uncachedLocalHour({0})", midnight);
		var afterNative = date.getHours();

		// Sys.putEnv alone, with no tzset of the program's own
		Sys.putEnv("TZ", "CST6");
		var putEnvHour:Int = untyped __cpp__("uncachedLocalHour({0})", midnight);
		var afterPutEnv = date.getHours();
		var other = Date.fromTime(midnight * 1000 + 1000).getHours();
		var again = date.getHours();

		Sys.putEnv("TZ", old);
		if (old == null)
			Sys.putEnv("TZ", null);

		Sys.stderr().writeString('utc $utc, native $nativeHour/$afterNative, putEnv $putEnvHour/$afterPutEnv, other $other, again $again\n');
		Sys.println("native conversion observes the new timezone: " + (utc == 0 && nativeHour == 19));
		Sys.println("cached date observes a native timezone change immediately: " + (afterNative == nativeHour));
		Sys.println("Sys.putEnv of TZ changes the timezone: " + (putEnvHour == 18 && afterPutEnv == 18));
		Sys.println("conversion after another timestamp observes the timezone: " + (other == 18 && again == 18));
	}
}
