import sys.net.Host;
import sys.net.Socket;

@:cppFileCode('
#ifdef HX_WINDOWS
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#endif
size_t _hx_std_socket_handle(Dynamic inSocket);
// The listener\'s port, read without Socket.host, which reports only IPv4
static int boundPort(Dynamic inSocket) {
 sockaddr_storage addr;
 #ifdef HX_WINDOWS
 int len = sizeof(addr);
 #else
 socklen_t len = sizeof(addr);
 #endif
 if (getsockname((decltype(socket(0,0,0)))_hx_std_socket_handle(inSocket), (sockaddr *)&addr, &len) != 0)
  return -1;
 if (addr.ss_family == AF_INET6)
  return ntohs(((sockaddr_in6 *)&addr)->sin6_port);
 return ntohs(((sockaddr_in *)&addr)->sin_port);
}
')
class Main {
 static function port(socket:Socket):Int {
  var handle:Dynamic = @:privateAccess socket.__s;
  return untyped __cpp__("boundPort({0})", handle);
 }

 // Accepts a connection on a listener on host, then sends a byte each way
 static function acceptAndTransfer(address:String, blocking:Bool):Bool {
  var host = new Host(address);
  var listener = new Socket();
  listener.bind(host, 0);
  listener.listen(1);
  if (!blocking) {
   listener.setBlocking(false);
   // Nothing is pending yet, so the accept reports that it would block
   var wouldBlock = false;
   try listener.accept() catch (e:Dynamic) wouldBlock = Std.string(e) == "Blocking";
   if (!wouldBlock) {
    listener.close();
    return false;
   }
  }
  var client = new Socket();
  client.connect(host, port(listener));
  if (Socket.select([listener], [], [], 5).read.length != 1) {
   client.close();
   listener.close();
   return false;
  }
  var ok = false;
  try {
   var accepted = listener.accept();
   accepted.setBlocking(true);
   client.output.writeByte(42);
   client.output.flush();
   accepted.output.writeByte(7);
   accepted.output.flush();
   ok = accepted.input.readByte() == 42 && client.input.readByte() == 7;
   accepted.close();
  } catch (e:Dynamic) {
   Sys.stderr().writeString("accept failed: " + e + "\n");
  }
  client.close();
  listener.close();
  return ok;
 }

 static function ipv6Available():Bool {
  try {
   var listener = new Socket();
   listener.bind(new Host("::1"), 0);
   listener.close();
   return true;
  } catch (e:Dynamic) {
   return false;
  }
 }

 static function main() {
  Sys.println("IPv4 accept and transfer work: " + (acceptAndTransfer("127.0.0.1", true) && acceptAndTransfer("127.0.0.1", false)));
  // A machine without IPv6 loopback fails here, rather than passing
  if (!ipv6Available()) {
   Sys.println("IPv6 loopback is unavailable");
   return;
  }
  Sys.println("blocking IPv6 accept and transfer work: " + acceptAndTransfer("::1", true));
  Sys.println("nonblocking IPv6 accept and transfer work: " + acceptAndTransfer("::1", false));
 }
}
