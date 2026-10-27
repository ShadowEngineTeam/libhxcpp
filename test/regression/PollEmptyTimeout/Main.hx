import sys.net.Host;
import sys.net.Socket;
import cpp.net.Poll;

class Main {
 // How long poll.events(timeout) takes, after checking it reports nothing
 static function wait(poll:Poll, timeout:Float):Float {
  var start = haxe.Timer.stamp();
  poll.events(timeout);
  var took = haxe.Timer.stamp() - start;
  if (poll.readIndexes[0] != -1 || poll.writeIndexes[0] != -1)
   throw "an idle poll reported a socket";
  if (Sys.getEnv("SHOW_TIME") == "1")
   Sys.stderr().writeString('  waited ${Math.round(took * 1e6)} us for $timeout s\n');
  return took;
 }

 static function main() {
  // A wait of 50 ms must take at least 25, which leaves room for the timer
  // and still tells a wait from an immediate return
  var poll = new Poll(1);
  poll.prepare([], []);
  Sys.println("empty poll waits for its timeout: " + (wait(poll, 0.05) >= 0.025));

  var listener = new Socket();
  listener.bind(new Host("127.0.0.1"), 0);
  listener.listen(1);
  var client = new Socket();
  client.connect(new Host("127.0.0.1"), listener.host().port);
  var accepted = listener.accept();
  poll.prepare([accepted], []);
  Sys.println("poll of an idle socket waits for its timeout: " + (wait(poll, 0.05) >= 0.025));

  poll.prepare([], []);
  Sys.println("poll emptied again waits for its timeout: " + (wait(poll, 0.05) >= 0.025));
  Sys.println("empty poll with no timeout returns at once: " + (wait(poll, 0) < 0.025));

  accepted.close();
  client.close();
  listener.close();
 }
}
