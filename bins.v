module main

import gg

fn (mut g Game) bins_init() {
	bbase := 170
	bstep := 150
	btop := 515
	bsize := Vec2{90, 33}
	g.bins = [
		Button{
			kind:  .glass
			pos:   Vec2{bbase + bstep * 0, btop}
			size:  bsize
			label: '1. Glass'
		},
		Button{
			kind:  .metal
			pos:   Vec2{bbase + bstep * 1, btop}
			size:  bsize
			label: '2. Metal'
		},
		Button{
			kind:  .paper
			pos:   Vec2{bbase + bstep * 2, btop}
			size:  bsize
			label: '3. Paper'
		},
		Button{
			kind:  .plastic
			pos:   Vec2{bbase + bstep * 3, btop}
			size:  bsize
			label: '4. Plastic'
		},
		Button{
			kind:  .organic
			pos:   Vec2{bbase + bstep * 4, btop}
			size:  bsize
			label: '5. Organic'
		},
	]
}

fn (mut g Game) bins_draw() {
	for mut b in g.bins {
		b.draw(g.ctx)
	}
}

fn (mut g Game) bins_on_mouse(e &gg.Event) {
	for mut b in g.bins {
		if b.clicked(e) {
			g.bins_choose(b.kind)
		}
	}
}

fn (mut g Game) bins_on_key(e &gg.Event) {
	match rune(e.char_code) {
		`1` { g.bins_choose(.glass) }
		`2` { g.bins_choose(.metal) }
		`3` { g.bins_choose(.paper) }
		`4` { g.bins_choose(.plastic) }
		`5` { g.bins_choose(.organic) }
		else {}
	}
}

fn (mut g Game) bins_choose(kind Kind) {
	for mut o in g.bins {
		o.selected = false
		o.shaking = 0
	}
	for mut b in g.bins {
		if b.kind == kind {
			b.selected = true
			g.sbin = b.kind
			b.shaking = 16
		}
	}
}
