import sys.net.Socket;
import sys.net.Host;
import cpp.net.Poll;

class Main {
 static function contains(indexes:Array<Int>,index:Int):Bool {
  for(value in indexes) {
   if(value==-1) return false;
   if(value==index) return true;
  }
  return false;
 }
 static function main() {
  var host=new Host("127.0.0.1");
  var reserved=new Socket();
  reserved.bind(host,0);
  var failed=new Socket();
  failed.setBlocking(false);
  // The connect to a bound port with no listener is pending until it fails,
  // which select reports on Windows as an exception and elsewhere as
  // writable. Where it fails at once, connect throws, and where it does not
  // fail in time (macOS keeps it pending), there is no failed connect for a
  // poll to report: the checks pass there. The bug is in the Windows poll,
  // so there the connect must fail.
  var untestable=false;
  try failed.connect(host,reserved.host().port) catch(_:Dynamic) untestable=true;
  if(!untestable) {
  var ready=Socket.select([],[failed],[failed],5);
  if(ready.write.length+ready.others.length==0) {
   if(Sys.systemName()=="Windows") throw "connection failure did not become ready";
   untestable=true;
  }
  }
  var server=new Socket();
  server.bind(host,0);
  server.listen(1);
  var idle=[];
  var peers=[];
  for(i in 0...64) {
   var socket=new Socket();
   socket.connect(host,server.host().port);
   peers.push(server.accept());
   idle.push(socket);
  }
  var poll=new Poll(65);
  poll.prepare([failed].concat(idle),[]);
  poll.events(0.1);
  Sys.println("failed first read socket is reported: "+(untestable || contains(poll.readIndexes,0)));
  poll.prepare(idle.concat([failed]),[]);
  poll.events(0.1);
  Sys.println("failed read socket beyond 64 is reported: "+(untestable || contains(poll.readIndexes,64)));
  poll.prepare([],[failed]);
  poll.events(0.1);
  Sys.println("failed write-only socket is reported: "+(untestable || contains(poll.writeIndexes,0)));
  for(socket in idle) socket.close();
  for(socket in peers) socket.close();
  failed.close();
  server.close();
  reserved.close();
 }
}