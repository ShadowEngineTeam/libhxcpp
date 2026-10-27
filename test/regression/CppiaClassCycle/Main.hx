// A cppia class whose super class chain leads back to itself. Linking it
// walked up the chain to collect inherited interfaces and never stopped, so
// a malformed 780-byte file hung its host (libhxcpp #257). The loader now
// rejects such a chain before walking it. Found by test/fuzz; the same input
// is in test/fuzz/regressions/cppia.
function main() {
	var data = haxe.crypto.Base64.decode("Q1BQSUIKMjYKMCAKMyBuZXcKNCBuYW1lCjUgZ3JlZXQKNyBjb3VudGVyCjYgaGVsbG8gCjEgIAo0IG1haW4KMiBfZwo0IHB1c2gKMSBzCjQgbGlzdAozIG1hcAozIF9nMQo2IGxlbmd0aAo2IHNldEludAo1IHRyYWNlCjUgY291bnQKNiBTY3JpcHQKMTUgc2VlZHMvU2NyaXB0Lph/CjYgcmFuZG9tCjQgemVybwo1IGFycmF5CjcgY3VycmVudAo3IGhhc05leHQKNCBuZXh0CjE0CjAgCjYgU2NyaXB0CjYgU3RyaW5nATQgdm9pZAozIGludAoxMiBBcnJheS5PYmplY3QKMTcgaGF4ZS5kcy5TdHJpbmdNYXAKOCBoYXhlLkxvZwo2IExhbWJkYQozIFN0ZAoyOCBoYXhlLml0ZXJhdG9ycy5BcnJheWVJdHJhdG9yCjkgQXJyYXkuQW55CjQgYm8vbAo3IER5bmFtaWMKMgpEAQAABQEBAAEBAQIAAgcDAQL+jxYAAgAJAQ4dAQIC/o8WAgBFRQACAgABAAADAgAHAgAJAiQcAQQvAmVlZTsFHQECOwYcAQQCAUVFAAQEATkAAQEABwMABwMACQcqASwI/pAWAAUFFwUACQMSBQkBAv6QFi0BAWU7CjkAEgUJAQL+kBYtAQFlOwo5ARIFCQEC/pAWLQEBZTsKOQIqASwL/pIWAAUFAv6QFioBLAz+kxYABgYtBgAJAioBLA3+nRYABAQ5ADNBbwL+nRYeBQ4C/pIWCQMqASwK/pQWAAEBIgUC/pIWAv6dFiMC/p0WEgYPAgL+kxYSAQMAAv6UFh4CDh4BAgL+lBYPAhwHEBEIEQIC/pMWPjATFhIHGGoRCRQBOQI5AAkBITsVRAoKAAUBAQABCgEWAAsHAwEW/t8VAAsACQIOHQoXOQAOHQoWAv7fFQIARUUAFgsAAgBFRQAXBAABAAAYDAAHDAAJAS8Mbx0KFx4LDh0KFgEAABkNAAcNAAkBLw0iCx0KFiQdChdLEQEHAE0A");
	try {
		cpp.cppia.Module.fromData(data.getData());
		Sys.println("loaded");
	} catch (e:Dynamic) {
		Sys.println(Std.string(e).indexOf("extends itself") >= 0 ? "rejected the cycle" : 'threw ');
	}
}
