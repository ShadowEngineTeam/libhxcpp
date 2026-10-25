class Item {
	public var value:Int;
	public function new(value:Int) this.value=value;
}
class Main {
	static function main() {
		var old=new Item(-1);
		var values=[for(i in 0...16384) old];
		cpp.vm.Gc.run(true);
		var correct=true;
		for(round in 0...32) {
			values[0]=new Item(round);
			values[8192]=new Item(round+100);
			values[16383]=new Item(round+200);
			cpp.vm.Gc.run(false);
			if(values[0].value!=round || values[8192].value!=round+100 || values[16383].value!=round+200) correct=false;
			if(values[1]!=old || values[16382]!=old) correct=false;
		}
		Sys.println("young array references survive collection: "+correct);
		cpp.vm.Gc.run(true);
		Sys.println("full collection preserves array edges: "+(values[0].value==31 && values[8192].value==131 && values[16383].value==231));
	}
}