// A function in a cppia file whose argument count is read as 1.9 billion.
// The loader sized its argument list from the count before reading any
// argument, allocating about 31 GB, so a malformed 602-byte file could end
// the host with out-of-memory (libhxcpp #257). Counts that size a list are
// now checked against the data left, as the class and string counts were.
// Found by test/fuzz; the same input is in test/fuzz/regressions/cppia.
function main() {
	var data = haxe.crypto.Base64.decode("Q1BQSUIKMjYKMCAKMyBuZXcKNCBuYW1lCjUgZ3JlZXQKNyBjb3VudGVyCjYgaGVsbG8gCjEgIAo0IG1haW4KMiBfZwo0IHB1c2gKMSBzCjQgbGlzdAozIG1hcAozIF9nMQo2IGxlbmd0aAo2IHNldEludAo1IHRyYWNlCjUgY291bnQKNiBTY3JpcHQKMTUgc2VlZHMvU2NyaXB0Lmh4CjYgcmFuZG9tCjQgemVybwo1IGFycmF5CjcgY3VycmVudAo3IGhhc05leHQKNCBuZXh0CjE0CjAgCjYgU2NyaXB0CjYgU3RyaW5nCjQgdm9pZAozIGludAoxMiBBcnJheS5PYmplY3QKMTcgaGF4ZS5kcy5TdHJpbmdNYXAKOCBoYYWa0bNvZwo2IExhbWJkYQozIFN0ZAoyOCBoYXhlLml0ZXJhdG9ycy5BcnJheWVJdHJhdG9yCjkgQXJyYXkuQW55CjQgYm9vbAo3IER5bmFtaWMKMgpEAQAABQEBAAEBAQIAAgcDAQL+jxYAAgAJAQ4dAQIC/o8WAgBFRQACAgABAAADAgAHAv////8cAQQvAmVlZTsFHQECOwYcAQQCAUVFAAQEATkAAQEABwNyZW1vCQcqASwI/pAWAAUFFwUYahEJFAE5AjkACQEhOxVECgAABQEBAAEKARYACwcDARb+3xUACwAJAg4dChc5AA4dChYC/t8VAgBFRQAWCwACAEVFABcEAAEAABgMAAcMAAkBLwxvHQoXHgsOHQoWAQAAGQ0ABw0ACQEvDSILHQoWJB0KF0sRAQcATQA=");
	try {
		cpp.cppia.Module.fromData(data.getData());
		Sys.println("loaded");
	} catch (e:Dynamic) {
		Sys.println(Std.string(e).indexOf("Bad count") >= 0 ? "rejected the count" : 'threw ');
	}
}
