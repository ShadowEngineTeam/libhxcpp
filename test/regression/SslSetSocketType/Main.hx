import cpp.NativeSsl;

// Uses a socket function so std's socket code is linked, as in any real use
function main() {
	sys.net.Host.localhost();
	final ctx = NativeSsl.ssl_new(NativeSsl.conf_new(false));
	try {
		NativeSsl.ssl_set_socket(ctx, [1, 2, 3]);
		Sys.println("no error");
	} catch (e:Dynamic) {
		Sys.println("caught");
	}
}
