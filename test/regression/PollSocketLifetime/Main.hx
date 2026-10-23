import sys.net.Socket;
import sys.net.Host;
@:cppFileCode('
#include <thread>
#include <hx/Native.h>
static void runJoined(Dynamic callback) {
 std::thread worker([callback]() mutable { hx::NativeAttach attach; callback(); });
 hx::AutoGCFreeZone freeZone;
 worker.join();
}
')
class Main {
 static var poll:cpp.net.Poll;
 static var weak:cpp.vm.WeakRef<Dynamic>;
 static var port:Int;
 static var keepAlive:Bool;
 static var held:Dynamic;
 static function prepare() {
  var client=new Socket();
  client.connect(new Host("127.0.0.1"),port);
  poll=new cpp.net.Poll(1);
  poll.prepare([client],[]);
  var handle:Dynamic = @:privateAccess client.__s;
  weak=new cpp.vm.WeakRef<Dynamic>(handle);
  held=keepAlive ? handle : null;
 }
 static function main() {
  var listener=new Socket();
  listener.bind(new Host("127.0.0.1"),0);
  listener.listen(1);
  port=listener.host().port;
  for (control in [true,false]) {
  keepAlive=control;
  untyped __cpp__("runJoined({0})",prepare);
  var peer=listener.accept();
  peer.setBlocking(false);
  for (i in 0...4) cpp.vm.Gc.run(true);
  var prefix=control ? "strong-root control" : "poll registration";
  Sys.println(prefix+" retains native socket: "+(weak.get()!=null));
  var open=false;
  try { peer.input.readByte(); } catch(e:haxe.io.Error) { open=e==haxe.io.Error.Blocked; } catch(e:Dynamic) {}
  Sys.println(prefix+" keeps connection open: "+open);
  var handle=weak.get();
  if (handle!=null) cpp.NativeSocket.socket_close(handle);
  poll.prepare([],[]);
  held=null;
  peer.close();
  }
  listener.close();
 }
}