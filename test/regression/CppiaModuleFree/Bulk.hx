import haxe.macro.Context;
import haxe.macro.Expr;

class Bulk {
	public static macro function build(count:Int):Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		var calls = [];
		for (k in 0...count) {
			var name = 'f$k';
			fields.push({
				name: name,
				access: [APublic, AStatic],
				pos: pos,
				kind: FFun({
					args: [{name: "a", type: macro :Int}, {name: "b", type: macro :String}],
					ret: macro :String,
					expr: macro {
						var s = b;
						var list = [];
						for (i in 0...a) {
							s += Std.string(i * $v{k}) + "x";
							if (s.length > 40)
								s = s.substr(1);
							list.push(s.length + $v{k});
						}
						var total = 0;
						for (v in list)
							total += v % 13;
						return switch (total % 3) {
							case 0: s + "a" + total;
							case 1: s.toUpperCase() + total;
							default: s.charAt(0) + total + $v{name};
						};
					}
				})
			});
			calls.push(macro out += $i{name}(3, "q").length);
		}
		fields.push({
			name: "all",
			access: [APublic, AStatic],
			pos: pos,
			kind: FFun({
				args: [],
				ret: macro :Int,
				expr: macro {
					var out = 0;
					$b{calls};
					return out;
				}
			})
		});
		return fields;
	}
}
