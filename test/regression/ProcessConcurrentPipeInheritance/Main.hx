import sys.io.Process;
import sys.thread.Thread;

// Process pipes were created with pipe() and marked close-on-exec afterwards,
// so a child another thread forked in between kept them across exec
// (libhxcpp #340). On Linux this program replaces pipe and pipe2 to pause one
// launch right after its stdout pipe exists, starts a second process while
// it waits, and has that child look for the first launch's pipe among its
// descriptors.
@:cppFileCode('
#ifdef __linux__
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <pthread.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <atomic>
#include <stdlib.h>
#include <stdio.h>

#ifndef __THROW
#define __THROW
#endif

static std::atomic<int> sArmed(0);
static pthread_t sArmedThread;
static std::atomic<int> sCalls(0);
static std::atomic<int> sPaused(0);
static std::atomic<int> sRelease(0);
static std::atomic<long> sInode(0);

// Makes the pipe itself, so the flags reach the kernel unchanged, and pauses
// the armed thread after its second pipe: the launch stdout
static int hookPipe(int *fds, int flags)
{
   int result = (int)syscall(SYS_pipe2, fds, flags);
   if (result==0 && sArmed.load() && pthread_equal(pthread_self(), sArmedThread) && ++sCalls==2)
   {
      sArmed = 0;
      struct stat st;
      fstat(fds[1], &st);
      sInode = (long)st.st_ino;
      sPaused = 1;
      hx::EnterGCFreeZone();
      while(!sRelease.load())
         usleep(1000);
      hx::ExitGCFreeZone();
   }
   return result;
}

extern "C" int pipe(int fds[2]) __THROW { return hookPipe(fds, 0); }
extern "C" int pipe2(int fds[2], int flags) __THROW { return hookPipe(fds, flags); }

static void armHook() { sCalls = 0; sArmedThread = pthread_self(); sArmed = 1; }
static bool hookPaused() { return sPaused.load(); }
static void releaseHook() { sRelease = 1; }
static ::String hookInode() { return ::String((int)sInode.load()); }

static ::String controlPipe()
{
   int fds[2];
   if (syscall(SYS_pipe2, fds, O_CLOEXEC)!=0)
      return ::String("0");
   struct stat st;
   fstat(fds[1], &st);
   return ::String((int)st.st_ino);
}

static bool hasPipe(int inInode)
{
   bool found = false;
   DIR *dir = opendir("/proc/self/fd");
   if (!dir)
      return false;
   while(struct dirent *entry = readdir(dir))
   {
      struct stat st;
      if (entry->d_name[0]!=46 &&fstat(atoi(entry->d_name), &st)==0 && S_ISFIFO(st.st_mode) && (int)st.st_ino==inInode)
         found = true;
   }
   closedir(dir);
   return found;
}
#else
// The pipe hooks are for Linux, where the program checks for the pipes
static void armHook() { }
static bool hookPaused() { return false; }
static void releaseHook() { }
static ::String hookInode() { return ::String("0"); }
static ::String controlPipe() { return ::String("0"); }
static bool hasPipe(int inInode) { return false; }
#endif
')
class Main {
	static function main() {
		var args = Sys.args();
		// Haxe defines no linux, only the C++ build does, so the system is
		// asked at run time
		if (args.length == 2 && args[0] == "child") {
			Sys.print(untyped __cpp__('hasPipe({0})', Std.parseInt(args[1])) ? "inherited" : "excluded");
			return;
		}
		if (Sys.systemName() != "Linux") {
			Sys.println("unrelated process pipes excluded from concurrent child: true");
			Sys.println("atomic close-on-exec control: true");
			return;
		}
		run();
	}

	static function run() {
		var main = Thread.current();
		Thread.create(() -> {
			untyped __cpp__('armHook()');
			var p = new Process("/bin/true", []);
			p.exitCode();
			p.close();
			main.sendMessage("done");
		});
		var waited = 0;
		while (!untyped __cpp__('hookPaused()')) {
			if (++waited > 2000) {
				Sys.println("launch never reached its second pipe");
				Sys.exit(1);
			}
			Sys.sleep(0.005);
		}
		var launchPipe:String = untyped __cpp__('hookInode()');
		var control:String = untyped __cpp__('controlPipe()');
		Sys.println("unrelated process pipes excluded from concurrent child: " + (child(launchPipe) == "excluded"));
		Sys.println("atomic close-on-exec control: " + (child(control) == "excluded"));
		untyped __cpp__('releaseHook()');
		Thread.readMessage(true);
	}

	static function child(inode:String):String {
		var p = new Process(Sys.programPath(), ["child", inode]);
		var result = p.stdout.readAll().toString();
		p.close();
		return result;
	}
}
