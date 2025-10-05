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
	ctx        &gg.Context = unsafe { nil }
	level      int         = 1
	state      State       = .running
	bins       []Button
	sbin       ?Kind
	background gg.Image
	song       &SongPlayer = new_song_player()
}

fn (mut g Game) restart() {
	g.song.restart()
}

fn (mut g Game) on_mouse(x f32, y f32, e &gg.Event) {
	// eprintln('>> ${@LOCATION}: x: ${x} | y: ${y}')
	g.bins_on_mouse(e)
}

fn (mut g Game) change_state(nstate State) {
	g.state = nstate
	g.song.pause(nstate == .paused)
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
		g.change_state(.running)
		return
	}
	if g.state == .running && e.typ == .key_up && e.key_code == .space {
		g.change_state(.paused)
		return
	}
	if g.state != .running {
		return
	}
	if e.typ == .char {
		g.bins_on_key(e)
		return
	}
	x := f32(e.mouse_x)
	y := f32(e.mouse_y)
	g.on_mouse(x, y, e)
}

fn on_frame(mut g Game) {
	g.song.work() or {}
	g.ctx.begin()
	g.ctx.draw_image(0, hheight, g.background.width, g.background.height, g.background)
	g.ctx.draw_text(5, 0, 'level: ${g.level} | state: ${g.state} | bin: ${g.sbin}',
		color: gg.green
		size:  32
	)
	g.ctx.draw_line(0, hheight, gwidth, hheight, gg.light_gray)
	g.bins_draw()
	g.ctx.end()
}

fn main() {
	mut g := &Game{}
	g.bins_init()
	g.restart()
	g.song.play_ogg_file(asset.get_path('./assets', 'songs/collecting_garbage.ogg'))!
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
	garden_path := asset.get_path('./assets', 'images/garden_path.png')
	g.background = g.ctx.create_image(garden_path)!
	g.ctx.run()
}
