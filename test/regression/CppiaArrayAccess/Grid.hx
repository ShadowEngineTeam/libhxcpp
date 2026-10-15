class Grid implements ArrayAccess<Int> {
	var cells = [0, 0, 0];

	public function new() {}

	public function __get(i:Int):Int
		return cells[i];

	public function __set(i:Int, v:Int):Int
		return cells[i] = v;
}
