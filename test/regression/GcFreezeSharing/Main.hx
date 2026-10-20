class Node {
	public var next:Node;
	public var value:Int;

	public function new(value:Int)
		this.value = value;
}

class Main {
	static function freeze<T>(o:T):T
		return untyped __cpp__('_hx_gc_freeze({0})', o);

	static function main() {
		var child = {value: 42};
		var parent = freeze({first: child, second: child});
		Sys.println("frozen children share identity: " + (parent.first == parent.second));
		Sys.println("frozen values preserved: " + (parent.first.value == 42 && parent.second.value == 42));

		var items = [1, 2, 3];
		var lists = freeze({a: items, b: items});
		Sys.println("frozen arrays share identity: " + (lists.a == lists.b && lists.a[2] == 3));

		var self = new Node(1);
		self.next = self;
		var frozenSelf = freeze(self);
		Sys.println("frozen self reference: " + (frozenSelf.next == frozenSelf && frozenSelf != self));

		var a = new Node(1);
		var b = new Node(2);
		a.next = b;
		b.next = a;
		var frozenA = freeze(a);
		Sys.println("frozen cycle: " + (frozenA.next.next == frozenA && frozenA.next.value == 2));
	}
}
