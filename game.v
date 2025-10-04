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
}

fn (mut g Game) restart() {
	eprintln('>> ${@LOCATION}')
}

fn (mut g Game) on_mouse(x f32, y f32, btn gg.MouseButton) {
	eprintln('>> ${@LOCATION}: x: ${x} | y: ${y} | btn: ${btn}')
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
	if e.typ != .mouse_down {
		return
	}
	x := f32(e.mouse_x)
	y := f32(e.mouse_y)
	g.on_mouse(x, y, e.mouse_button)
}

fn on_frame(mut g Game) {
	g.ctx.begin()
	g.ctx.draw_text(5, 0, 'level: ${g.level} | state: ${g.state}', color: gg.green, size: 32)
	g.ctx.draw_line(0, hheight, gwidth, hheight, gg.light_gray)
	g.ctx.end()
}

fn main() {
	mut g := &Game{}
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
	)
	g.ctx.run()
}
