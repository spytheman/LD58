module main

import gg
import os.asset

const gwidth = 948
const gheight = 533
const hheight = 33

enum State {
	running
	paused
	finished
}

@[heap]
struct Game {
mut:
	ctx   &gg.Context = unsafe { nil }
	level int         = 1
	state State       = .running
	bins  []Button
	sbin  ?Kind
}

fn (mut g Game) restart() {
	eprintln('>> ${@LOCATION}')
}

fn (mut g Game) choose_bin(kind Kind) {
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

fn (mut g Game) on_mouse(x f32, y f32, e &gg.Event) {
	// eprintln('>> ${@LOCATION}: x: ${x} | y: ${y}')
	for mut b in g.bins {
		if b.clicked(e) {
			g.choose_bin(b.kind)
		}
	}
}

fn on_event(e &gg.Event, mut g Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape { g.ctx.quit() }
			.r { g.restart() }
			else {}
		}
		return
	}
	if g.state == .finished {
		return
	}
	if g.state == .paused && e.typ == .key_up && e.key_code == .space {
		g.state = .running
		return
	}
	if g.state == .running && e.typ == .key_up && e.key_code == .space {
		g.state = .paused
		return
	}
	if g.state != .running {
		return
	}
	if e.typ == .char {
		match rune(e.char_code) {
			`1` { g.choose_bin(.junk) }
			`2` { g.choose_bin(.metal) }
			`3` { g.choose_bin(.plastic) }
			`4` { g.choose_bin(.organic) }
			else {}
		}
		return
	}
	x := f32(e.mouse_x)
	y := f32(e.mouse_y)
	g.on_mouse(x, y, e)
}

fn on_frame(mut g Game) {
	g.ctx.begin()
	g.ctx.draw_text(5, 0, 'level: ${g.level} | state: ${g.state} | bin: ${g.sbin}',
		color: gg.green
		size:  32
	)
	g.ctx.draw_line(0, hheight, gwidth, hheight, gg.light_gray)
	for mut b in g.bins {
		b.draw(g.ctx)
	}
	g.ctx.end()
}

fn main() {
	mut g := &Game{}
	g.bins = [
		Button{
			kind:  .junk
			pos:   Vec2{200, 510}
			size:  Vec2{80, 33}
			label: 'Junk'
		},
		Button{
			kind:  .metal
			pos:   Vec2{390, 510}
			size:  Vec2{80, 33}
			label: 'Metal'
		},
		Button{
			kind:  .plastic
			pos:   Vec2{5710, 510}
			size:  Vec2{80, 33}
			label: 'Plastic'
		},
		Button{
			kind:  .organic
			pos:   Vec2{760, 510}
			size:  Vec2{80, 33}
			label: 'Organic'
		},
	]
	g.restart()
	g.ctx = gg.new_context(
		bg_color:     gg.black
		width:        gwidth
		height:       gheight
		window_title: 'Garbage Collector (LD58)'
		user_data:    g
		frame_fn:     on_frame
		event_fn:     on_event
		font_path:    asset.get_path('./assets', 'fonts/Imprima-Regular.ttf')
		sample_count: 2
	)
	g.ctx.run()
}
