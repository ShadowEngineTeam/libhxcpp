// An empty array may have no buffer. copy, splice, concat and insert passed
// that null buffer to memcpy or memmove for zero bytes, which is undefined in C;
// UBSan reports it if it comes back. Each also runs on arrays of objects, whose
// copies go through the generational write barrier.
function main() {
	var ints:Array<Int> = [];
	var objects:Array<String> = [];
	Sys.println("copy: " + ints.copy().length + " " + objects.copy().length);
	Sys.println("splice: " + ints.splice(0, 0).length + " " + objects.splice(0, 5).length);
	Sys.println("concat: " + ints.concat([]).length + " " + objects.concat([]).length + " " + [].concat([1, 2]).length);
	Sys.println("slice: " + ints.slice(0, 0).length + " " + objects.slice(0).length);
	var grown = [1, 2, 3];
	grown.splice(1, 0);
	Sys.println("splice nothing from a full array: " + grown);
	var tail = [1, 2, 3];
	tail.splice(1, 2);
	Sys.println("splice to the end: " + tail);
	ints.insert(0, 7);
	Sys.println("insert into empty: " + ints);
}
