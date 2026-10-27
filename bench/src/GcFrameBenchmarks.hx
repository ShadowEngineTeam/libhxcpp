package;

import Benchmark.Rng;
import haxe.Timer;

private class FrameItem {
	public final id:Int;
	public final value:Int;

	public function new(id:Int) {
		this.id = id;
		value = id ^ 0x13579;
	}
}

private class FrameEntity {
	public final id:Int;
	public final label:String;
	public final inventory:Array<FrameItem>;
	public var target:FrameEntity;

	public function new(id:Int) {
		this.id = id;
		label = "entity-" + id;
		inventory = [for (slot in 0...4) new FrameItem(id * 4 + slot)];
	}
}

private class FrameParticle {
	public final value:Int;
	public final next:FrameParticle;

	public function new(value:Int, next:FrameParticle) {
		this.value = value;
		this.next = next;
	}
}

/**
	Frame latency with a persistent world, graph mutation, temporary objects
	and occasional bursts. There is no sleep or explicit collection inside a
	frame. Work checksums and final graph checks run in both collector modes.
**/
class GcFrames extends Benchmark {
	static inline var ENTITIES = 150000;
	static inline var FRAMES = 2000;
	final entities:Array<FrameEntity> = [];
	final grid:Array<Array<FrameEntity>> = [];
	var particles:FrameParticle;
	var events:Array<{target:FrameEntity, message:String}> = [];
	var burst:Array<FrameItem> = [];

	public function new() {
		super("gc_frames", "frames", FRAMES, true);
	}

	override public function setup() {
		for (i in 0...ENTITIES)
			entities.push(new FrameEntity(i));
		for (i in 0...512)
			grid.push([for (j in 0...64) entities[(i * 64 + j) % ENTITIES]]);
	}

	override public function run():Int {
		var rng = new Rng(0x1234567);
		var sum = 0;
		for (frame in 0...FRAMES) {
			var started = Timer.stamp();
			particles = null;
			for (i in 0...2000)
				particles = new FrameParticle(frame + i, particles);
			var p = particles;
			while (p != null) {
				sum = (sum + p.value) | 0;
				p = p.next;
			}
			events = [];
			for (i in 0...100) {
				var target = entities[rng.below(ENTITIES)];
				events.push({target: target, message: "event-" + frame + ":" + i});
			}
			for (event in events)
				sum = (sum + event.target.id + event.message.length) | 0;
			for (i in 0...3000) {
				var entity = entities[rng.below(ENTITIES)];
				entity.target = entities[rng.below(ENTITIES)];
				sum = (sum + entity.id + entity.target.id) | 0;
			}
			for (i in 0...300) {
				var entity = entities[rng.below(ENTITIES)];
				var slot = rng.below(4);
				entity.inventory[slot] = new FrameItem(frame * 300 + i);
				sum = (sum + entity.inventory[slot].value) | 0;
			}
			for (i in 0...60) {
				var cell = grid[rng.below(512)];
				var slot = rng.below(64);
				cell[slot] = entities[rng.below(ENTITIES)];
				sum = (sum + cell[slot].id) | 0;
			}
			if ((frame & 63) == 0) {
				burst = [for (i in 0...5000) new FrameItem(frame * 5000 + i)];
				for (item in burst)
					sum = (sum + item.value) | 0;
			}
			latencies.push(Timer.stamp() - started);
		}
		// Check retained payloads without folding mutable state from earlier
		// samples into the checksum. Every run uses the same random sequence.
		for (entity in entities) {
			if (entity.label != "entity-" + entity.id || entities[entity.id] != entity)
				throw "gc_frames entity graph changed";
			if (entity.target != null && entities[entity.target.id] != entity.target)
				throw "gc_frames target changed";
			for (item in entity.inventory)
				if (item.value != (item.id ^ 0x13579))
					throw "gc_frames inventory changed";
			sum = (sum * 31 + entity.id + entity.label.length) | 0;
		}
		for (cell in grid)
			for (entity in cell)
				if (entities[entity.id] != entity)
					throw "gc_frames grid changed";
		return sum;
	}
}
