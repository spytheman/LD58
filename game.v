module main

import gg
import log
import os.asset
import math

const gwidth = 948
const gheight = 533

enum State {
	running
	paused
	finished
}

@[heap]
struct Game {
mut:
	ctx          &gg.Context = unsafe { nil }
	level        int         = 1
	state        State       = .running
	bins         []Button
	sbin         ?Kind
	level_images []gg.Image
	background   gg.Image
	song         &SongPlayer = new_song_player()
	spos         Vec2
	epos         Vec2
	player       Player
	items        []Item
	//
	potential_item_positions []Vec2
}

struct Item {
	pos  Vec2
	img  gg.Image
	kind Kind
}

struct Player {
mut:
	pos   Vec2
	speed Vec2
	angle f32
	img   gg.Image
}

fn (mut g Game) restart() {
	g.player.pos = g.spos
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
	if e.typ == .key_down {
		g.bins_on_key(e)
		match e.key_code {
			.page_up {
				g.next_level()
			}
			.w, .up {
				g.player.speed = Vec2{0, -1}
				g.player.angle = 0
			}
			.s, .down {
				g.player.speed = Vec2{0, 1}
				g.player.angle = math.pi
			}
			.a, .left {
				g.player.speed = Vec2{-1, 0}
				g.player.angle = math.pi / 2
			}
			.d, .right {
				g.player.speed = Vec2{1, 0}
				g.player.angle = -math.pi / 2
			}
			else {}
		}
		return
	}
	x := f32(e.mouse_x)
	y := f32(e.mouse_y)
	g.on_mouse(x, y, e)
}

fn (mut g Game) next_level() {
	g.level++
	dump(g.level)
	dump(g.level_images.len)
	lidx := g.level % g.level_images.len
	dump(lidx)
	g.background = g.level_images[lidx]
	dump(g.background)
	g.find_start_and_exit_spots()
	g.player.speed.zero()
}

fn (mut g Game) player_move() {
	size := 2
	npos := g.player.pos + g.player.speed.mul_scalar(5)
	for y in int(npos.y - size) .. int(npos.y + size) {
		for x in int(npos.x - size) .. int(npos.x + size) {
			c := g.bgpixel(x: x, y: y)
			if c == gg.black {
				return
			}
		}
	}
	g.player.pos = g.player.pos + g.player.speed.mul_scalar(2)
	nc := g.bgpixel(g.player.pos)
	if nc == gg.blue {
		g.next_level()
	}
}

fn on_frame(mut g Game) {
	g.song.work() or {}
	g.ctx.begin()
	g.ctx.draw_image(0, 0, g.background.width, g.background.height, g.background)
	for p in g.potential_item_positions {
		g.ctx.draw_rect_filled(p.x, p.y, 5, 5, gg.green)
	}
	g.ctx.draw_image_with_config(
		img_rect: gg.Rect{
			x: g.player.pos.x - g.player.img.width / 2
			y: g.player.pos.y - g.player.img.height / 2
		}
		img:      &g.player.img
		rotation: f32(math.degrees(g.player.angle))
	)
	g.player_move()
	g.bins_draw()
	g.ctx.draw_text(gwidth - 85, gheight - 24, 'Level: ${g.level}', color: gg.gray)
	g.ctx.draw_text(15, gheight - 24, '${g.state}', color: gg.gray)
	g.ctx.end()
}

fn (mut g Game) bgpixel(pos Vec2) gg.Color {
	x, y := int_max(0, int_min(g.background.width - 1, int(pos.x))), int_max(0, int_min(g.background.height - 1,
		int(pos.y)))
	return unsafe { &gg.Color(g.background.data)[y * g.background.width + x] }
}

fn (mut g Game) find_start_and_exit_spots() {
	log.info('>start find_start_and_exit_spots')
	defer { log.info('>end') }
	g.potential_item_positions.clear()
	g.player.pos.zero()
	g.spos.zero()
	g.epos.zero()
	bp := unsafe { &gg.Color(g.background.data) }
	for y in 0 .. gheight {
		for x in 0 .. gwidth {
			c := unsafe { *bp }
			unsafe { bp++ }
			if c.a >= 120 && c.a <= 128 {
				pos := Vec2{x, y}
				if c.r == 255 {
					g.spos = pos
					g.player.pos = g.spos
				}
				if c.b == 255 {
					g.epos = pos
				}
				if c.g == 255 {
					g.potential_item_positions << pos
				}
			}
		}
	}
}

fn main() {
	mut g := &Game{}
	g.bins_init()
	g.restart()
	g.song.play_ogg_file(asset.get_path('./assets', 'songs/collecting_garbage.ogg'))!
	g.ctx = gg.new_context(
		bg_color:     gg.white
		width:        gwidth
		height:       gheight
		window_title: 'Garbage Collector (LD58)'
		user_data:    g
		frame_fn:     on_frame
		event_fn:     on_event
		font_path:    asset.get_path('./assets', 'fonts/Imprima-Regular.ttf')
		sample_count: 2
	)
	g.player.img = g.ctx.create_image(asset.get_path('./assets', 'images/player.png'))!
	for i in 0 .. 7 + 1 {
		ipath := asset.get_path('./assets', 'images/${i}.png')
		g.level_images << g.ctx.create_image(ipath)!
	}
	g.background = g.level_images[3]
	dump(g.background.path)
	g.find_start_and_exit_spots()
	g.ctx.run()
}
