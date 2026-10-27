import sys.net.Host;

@:cppFileCode('
#include <thread>
#include <atomic>
#include <vector>
#include <hx/Native.h>
String _hx_std_host_to_string_ipv6(Array<unsigned char> ip);
// Formats ip on threads that all start at once, the first calls in the
// process, and counts the results that are not expected
static int formatTogether(Array<unsigned char> ip, String expected, int threads) {
 std::atomic<int> ready(0);
 std::atomic<bool> go(false);
 std::atomic<int> wrong(0);
 std::vector<std::thread> workers;
 for (int i = 0; i < threads; i++)
  workers.emplace_back([&]() {
   hx::NativeAttach attach;
   hx::EnterGCFreeZone();
   ready++;
   while (!go)
    std::this_thread::yield();
   hx::ExitGCFreeZone();
   String got = _hx_std_host_to_string_ipv6(ip);
   if (got != expected)
    wrong++;
  });
 hx::AutoGCFreeZone freeZone;
 while (ready < threads)
  std::this_thread::yield();
 go = true;
 for (auto &worker : workers)
  worker.join();
 return wrong;
}
')
class Main {
 static function main() {
  var host = new Host("::1");
  var ip:haxe.io.BytesData = @:privateAccess host.ipv6;
  if (ip == null) {
   Sys.println("::1 did not resolve to an IPv6 address");
   return;
  }
  var wrong:Int = untyped __cpp__("formatTogether({0}, {1}, 32)", ip, "::1");
  Sys.println("concurrent first IPv6 formatting returns complete addresses: " + (wrong == 0));
  wrong = untyped __cpp__("formatTogether({0}, {1}, 32)", ip, "::1");
  Sys.println("concurrent later IPv6 formatting returns complete addresses: " + (wrong == 0));
  Sys.println("later IPv6 formatting is correct: " + (host.toString() == "::1"));
  Sys.println("IPv4 formatting is correct: " + (new Host("127.0.0.1").toString() == "127.0.0.1"));
 }
}
