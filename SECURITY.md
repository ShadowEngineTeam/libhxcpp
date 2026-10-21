# Security policy

## Supported versions

Fixes go into the latest minor version of the current major line, as a patch release (see [RELEASING.md](RELEASING.md)). When a new major version is released, the previous major line's latest minor version gets security fixes for six months more.

| Version | Supported |
|---|---|
| 6.x, latest minor | Yes |
| hxcpp before libhxcpp 6.0.0 | No |

libhxcpp supports the code that Haxe 4.2 and later generates for the C++ target. Support for a Haxe version is only dropped in a major release, and announced in [Changes.md](Changes.md).

## Reporting a vulnerability

Report it privately with GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**. Please do not open a public issue for it.

Include the libhxcpp version, the platform and compiler, and the smallest Haxe or C++ program that shows the problem. We aim to reply within a week, and to credit the reporter in the fix and in [Changes.md](Changes.md) unless you ask us not to.

## Bundled libraries

libhxcpp builds mbedTLS, PCRE2, SQLite and zlib from source in `project/thirdparty`. A vulnerability in one of them should also be reported to its own project; we pick up the fix in a libhxcpp release and list it in Changes.md.

## What is not a vulnerability

A cppia script runs with the full privileges of its host, like any other code the host loads, so running an untrusted script is not a sandbox. A malformed `.cppia` file should fail to load with an error rather than crash the host, and a crash there is a bug worth reporting.
