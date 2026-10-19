// A host interface with type parameters: the host compiles every K, V and W
// argument as an object
interface HostMap<K, V, W> {
	function exists(key:K):Bool;
	function get(key:K):Null<V>;
	function set(key:K, value:V):Void;
	function scale(key:K, by:W, round:Bool):Float;
}
