// Libraries that make socket handles of their own, such as CrossByte's
// accept, declare a SocketWrapper in stock hxcpp's layout, the descriptor
// after the object header, and give it the socket kind. The runtime read its
// own wrapper's later fields from such a handle, so closing one read what
// followed it in memory as the read-ahead buffer and wrote through it.
@:cppFileCode('
#ifdef HX_WINDOWS
typedef size_t LibrarySocket;
#else
typedef int LibrarySocket;
#endif

static int sSocketType = 0;

struct SocketWrapper : public hx::Object
{
	LibrarySocket socket;
	// What follows a handle in memory, which is not part of it
	size_t after[4];

	int __GetType() const override { return sSocketType; }
};

static bool closeLibraryHandle()
{
	Dynamic probe = _hx_std_socket_new(false, false);
	sSocketType = probe->__GetType();
	_hx_std_socket_close(probe);

	SocketWrapper *handle = new SocketWrapper();
	handle->socket = (LibrarySocket)-1;
	for(int i=0;i<4;i++)
		handle->after[i] = 16;
	_hx_std_socket_close(handle);
	return handle->socket==(LibrarySocket)-1 && handle->after[0]==16 && handle->after[3]==16;
}
')
class Main {
	static function main() {
		// Windows needs the socket library started, which sys.net.Host does as it loads
		cpp.NativeSocket.socket_init();
		Sys.println("a library's socket handle closes without the memory after it: " + (untyped __cpp__("closeLibraryHandle()") : Bool));
	}
}
