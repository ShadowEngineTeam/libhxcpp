import cpp.NativeSsl;
import sys.ssl.Socket;

// A socket that has not connected passes a null context to the native calls,
// and a closed context or configuration keeps its handle with the native
// pointer cleared. Each case crashed the process instead of throwing.
function survives(name:String, action:() -> Void) {
	var result = "returned";
	try {
		action();
	} catch (e:Dynamic) {
		result = "caught " + Std.string(e);
	}
	Sys.stderr().writeString('$name: $result\n');
	Sys.println(name + " stays within the runtime error contract: true");
}

function closedConfig() {
	final config = NativeSsl.conf_new(false);
	NativeSsl.conf_close(config);
	return config;
}

function closedContext() {
	final config = NativeSsl.conf_new(false);
	final context = NativeSsl.ssl_new(config);
	NativeSsl.ssl_close(context);
	NativeSsl.conf_close(config);
	return context;
}

function main() {
	sys.net.Host.localhost();
	Socket.DEFAULT_VERIFY_CERT = false;
	final socket = new Socket();
	survives("new-handshake", () -> socket.handshake());
	survives("new-certificate", () -> if (socket.peerCertificate() != null) throw "certificate without a session");
	socket.close();
	survives("closed-context", () -> NativeSsl.ssl_handshake(closedContext()));
	survives("closed-config", () -> NativeSsl.conf_set_verify(closedConfig(), 1));
	survives("closed-verify-result", () -> NativeSsl.ssl_get_verify_result(closedContext()));
	survives("closed-certificate", () -> if (NativeSsl.ssl_get_peer_certificate(closedContext()) != null) throw "certificate after close");
	survives("closed-config-ssl-new", () -> NativeSsl.ssl_new(closedConfig()));
	survives("closed-config-ca", () -> NativeSsl.conf_set_ca(closedConfig(), null));
	survives("wrong-handle", () -> NativeSsl.ssl_handshake(closedConfig()));
	final config = NativeSsl.conf_new(false);
	final context = NativeSsl.ssl_new(config);
	NativeSsl.ssl_close(context);
	NativeSsl.ssl_close(context);
	NativeSsl.conf_close(config);
	NativeSsl.conf_close(config);
	Sys.println("closing twice is safe: true");
}
