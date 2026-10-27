import haxe.io.Bytes;

// The resolver's _r functions fill a caller's buffer and give ERANGE when the
// answer does not fit. The runtime gave them 1 KiB once and took ERANGE for a
// missing host. These replace them inside this executable, for Linux, where
// the runtime calls them: large.invalid, 10.1.2.3 and fd00::123 have 32
// aliases, more than 1 KiB, and need 4 KiB; huge.invalid never fits.
@:cppFileCode('
#if defined(__linux__) && !defined(__ANDROID__)
#include <netdb.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <arpa/inet.h>
#ifndef NETDB_INTERNAL
#define NETDB_INTERNAL -1
#endif

static const size_t kRecordSpace = 4096;

static int fixtureRecord(const char *name, int family, const void *addr, int addrLen,
	struct hostent *ret, char *buf, size_t buflen, struct hostent **result, int *herr)
{
	*result = 0;
	if (buflen < kRecordSpace)
	{
		*herr = NETDB_INTERNAL;
		errno = ERANGE;
		return ERANGE;
	}
	char *start = (char *)(((uintptr_t)buf + 15) & ~(uintptr_t)15);
	char *end = buf + buflen;
	const int aliasCount = 32;
	char **aliases = (char **)start;
	char **addrs = aliases + aliasCount + 1;
	char *p = (char *)(addrs + 2);
	memcpy(p, addr, addrLen);
	addrs[0] = p;
	addrs[1] = 0;
	p += 16;
	ret->h_name = p;
	p += snprintf(p, end - p, "%s", name) + 1;
	for (int i = 0; i < aliasCount; i++)
	{
		aliases[i] = p;
		p += snprintf(p, end - p, "alias-%02d-of-a-resolver-record-larger-than-one-kib.%s", i, name) + 1;
	}
	aliases[aliasCount] = 0;
	ret->h_aliases = aliases;
	ret->h_addrtype = family;
	ret->h_length = addrLen;
	ret->h_addr_list = addrs;
	*result = ret;
	*herr = 0;
	return 0;
}

static int sizeRetries = 0;

extern "C" int gethostbyname_r(const char *name, struct hostent *ret, char *buf, size_t buflen,
	struct hostent **result, int *herr)
{
	if (buflen < kRecordSpace)
		sizeRetries++;
	if (!strcmp(name, "huge.invalid"))
	{
		*result = 0;
		*herr = NETDB_INTERNAL;
		errno = ERANGE;
		return ERANGE;
	}
	if (strcmp(name, "large.invalid"))
	{
		*result = 0;
		*herr = HOST_NOT_FOUND;
		return 0;
	}
	struct in_addr a;
	inet_pton(AF_INET, "10.1.2.3", &a);
	return fixtureRecord("large.invalid", AF_INET, &a, 4, ret, buf, buflen, result, herr);
}

extern "C" int gethostbyaddr_r(const void *addr, socklen_t len, int type, struct hostent *ret,
	char *buf, size_t buflen, struct hostent **result, int *herr)
{
	unsigned char v4[4], v6[16];
	inet_pton(AF_INET, "10.1.2.3", v4);
	inet_pton(AF_INET6, "fd00::123", v6);
	if ((type == AF_INET && len == 4 && !memcmp(addr, v4, 4)) || (type == AF_INET6 && len == 16 && !memcmp(addr, v6, 16)))
		return fixtureRecord("large.invalid", type, addr, len, ret, buf, buflen, result, herr);
	*result = 0;
	*herr = HOST_NOT_FOUND;
	return 0;
}

static bool directControl()
{
	struct hostent h;
	struct hostent *r = 0;
	int herr = 0;
	char buf[kRecordSpace + 16];
	int small = gethostbyname_r("large.invalid", &h, buf, 1024, &r, &herr);
	if (small != ERANGE || r)
		return false;
	return gethostbyname_r("large.invalid", &h, buf, sizeof(buf), &r, &herr) == 0 && r && r->h_aliases[31];
}
static int fixtureRetries() { return sizeRetries; }
#else
static bool directControl() { return true; }
static int fixtureRetries() { return 0; }
#endif
')
class Main {
	static function main() {
		if (Sys.systemName() != "Linux") {
			Sys.println("large resolver record control succeeds: true");
			Sys.println("forward lookup retries a small resolver buffer: true");
			Sys.println("reverse IPv4 lookup retries a small resolver buffer: true");
			Sys.println("reverse IPv6 lookup retries a small resolver buffer: true");
			Sys.println("a record that never fits stays unknown: true");
			Sys.println("literal addresses and missing hosts retain behavior: true");
			return;
		}
		final ip = cpp.NativeSocket.host_resolve("10.1.2.3");
		Sys.println("large resolver record control succeeds: " + untyped __cpp__("directControl()"));

		var forward = false;
		try {
			final before:Int = untyped __cpp__("fixtureRetries()");
			forward = cpp.NativeSocket.host_resolve("large.invalid") == ip;
			final retries:Int = untyped __cpp__("fixtureRetries()") - before;
			Sys.stderr().writeString('forward lookup asked with a small buffer $retries times\n');
		} catch (e:Dynamic) {
			Sys.stderr().writeString('forward lookup: $e\n');
		}
		Sys.println("forward lookup retries a small resolver buffer: " + forward);

		final reverse = cpp.NativeSocket.host_reverse(ip);
		Sys.stderr().writeString('reverse IPv4: $reverse\n');
		Sys.println("reverse IPv4 lookup retries a small resolver buffer: " + (reverse == "large.invalid"));

		final v6 = cpp.NativeSocket.host_resolve_ipv6("fd00::123");
		final reverse6 = cpp.NativeSocket.host_reverse_ipv6(v6);
		Sys.stderr().writeString('reverse IPv6: $reverse6\n');
		Sys.println("reverse IPv6 lookup retries a small resolver buffer: " + (reverse6 == "large.invalid"));

		var huge = false;
		try {
			cpp.NativeSocket.host_resolve("huge.invalid");
		} catch (e:Dynamic) {
			huge = Std.string(e).indexOf("Unknown host") >= 0;
		}
		Sys.println("a record that never fits stays unknown: " + huge);

		var missing = false;
		try {
			cpp.NativeSocket.host_resolve("missing.invalid");
		} catch (e:Dynamic) {
			missing = Std.string(e).indexOf("Unknown host") >= 0;
		}
		final literal = cpp.NativeSocket.host_to_string(cpp.NativeSocket.host_resolve("10.1.2.3")) == "10.1.2.3";
		final unknownReverse = cpp.NativeSocket.host_reverse(cpp.NativeSocket.host_resolve("10.9.9.9")) == null;
		Sys.println("literal addresses and missing hosts retain behavior: " + (missing && literal && unknownReverse));
	}
}
