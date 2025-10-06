module main

import gg
import os.asset
import rand
import math

const gwidth = 948
const gheight = 533

enum State {
	working
	paused
	finished
}

@[heap]
struct Game {
mut:
	ctx             &gg.Context = unsafe { nil }
	day             int         = 1
	state           State
	rotation        f32
	mute_btn        Button
	bins            []Button
	sbin            ?Kind
	overlay_img_idx int
	overlay_img_mem &u8 = unsafe { nil }
	day_images      []&gg.Image
	all_item_images map[string]gg.Image
	background      &gg.Image   = unsafe { nil }
	song            &SongPlayer = new_song_player()
	spos            Vec2
	player          Player
	items           []Item
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
	pos    Vec2
	speed  Vec2
	meters u64
	angle  f32
	img    gg.Image
}

fn (mut g Game) restart() {
	g.next_day(g.day)
	g.song.restart()
}

fn (mut g Game) on_mouse(x f32, y f32, e &gg.Event) {
	g.bins_on_mouse(e)
	if g.mute_btn.clicked(e) {
		g.mute_trigger()
	}
}

fn (mut g Game) change_state(nstate State) {
	g.state = nstate
	g.song.pause(nstate == .paused)
}

@[if develop ?]
fn (mut g Game) on_develop(e &gg.Event) {
	if e.typ == .key_down {
		match e.key_code {
			.r { g.restart() }
			.page_up { g.next_day(g.day + 1) }
			.page_down { g.next_day(g.day - 1) }
			else {}
		}
	}
}

fn (mut g Game) bgpixel(pos Vec2) gg.Color {
	x, y := int_max(0, int_min(g.background.width - 1, int(pos.x))), int_max(0, int_min(g.background.height - 1,
		int(pos.y)))
	return unsafe { &gg.Color(g.background.data)[y * g.background.width + x] }
}

fn (mut g Game) find_start_and_exit_spots() {
	bp := g.get_b_ptr() or { return }
	g.potential_item_positions.clear()
	g.items.clear()
	g.player.pos.zero()
	g.spos.zero()
	outer_y: for y in 0 .. gheight - 1 {
		for x in 0 .. gwidth {
			c := unsafe { *bp }
			if c.a >= 100 && c.a <= 200 {
				pos := Vec2{x, y}
				_ = pos.str() // TODO: this is needed for tcc, investigate why
				if c.r == 255 {
					g.spos = pos
					g.player.pos = g.spos
					break outer_y
				}
				if c.g == 255 {
					g.potential_item_positions << pos
				}
			}
			unsafe { bp++ }
		}
	}
	g.add_items_on_some_positions()
}

fn (mut g Game) add_items_on_some_positions() {
	positions := rand.choose(g.potential_item_positions, int_max(5, g.potential_item_positions.len / 5)) or {
		return
	}
	for ipos in positions {
		ikind := unsafe { Kind(rand.int_in_range(0, 5) or { 0 }) }
		kpath := rand.element(paths_by_kind[ikind]) or { '' }
		g.items << Item{
			pos:  ipos
			kind: ikind
			img:  unsafe { g.all_item_images[kpath] }
		}
	}
}

fn (mut g Game) next_day(nday int) {
	g.day = nday
	if g.day_images.len > 0 {
		lidx := int_max(0, g.day) % g.day_images.len
		g.background = g.day_images[lidx]
		g.copy_background_to_overlay()
	}
	g.find_start_and_exit_spots()
	g.player.speed.zero()
}

fn (mut g Game) player_move() {
	if g.state == .paused {
		return
	}
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
	if npos.y < -1 || npos.y > gheight - 35 {
		return
	}
	if npos.x < -1 || npos.x > gwidth - 3 {
		return
	}
	g.player.pos = g.player.pos + g.player.speed.mul_scalar(2)
	g.player.meters += u64(g.player.speed.magnitude())
	nc := g.bgpixel(g.player.pos)
	if nc == gg.green {
		g.next_day(g.day + 1)
	}
	for item_idx, mut item in g.items {
		if g.player.pos.distance(item.pos) < g.player.img.width / 2 {
			for mut b in g.bins {
				if item.kind == b.kind {
					b.counter++
				}
			}
			g.items.delete(item_idx)
			if g.items.len == 0 {
				g.enable_exit()
			}
			break
		}
	}
}

fn (mut g Game) get_b_ptr() ?&gg.Color {
	if isnil(g.background) {
		return none
	}
	bp := unsafe { &gg.Color(g.background.data) }
	if isnil(bp) {
		return none
	}
	return bp
}

fn (mut g Game) enable_exit() {
	bp := g.get_b_ptr() or { return }
	for _ in 0 .. g.background.height {
		for _ in 0 .. g.background.width {
			c := unsafe { *bp }
			if c == gg.blue {
				unsafe {
					*bp = gg.green
				}
			}
			unsafe { bp++ }
		}
	}
	g.copy_background_to_overlay()
}

fn (mut g Game) items_draw() {
	r := f32(math.degrees(g.rotation) / 90)
	for idx, item in g.items {
		mut irot := r + idx * 10
		if g.sbin != none {
			if g.sbin == item.kind {
				irot *= 10
			}
		}
		g.ctx.draw_image_with_config(
			img_rect: gg.Rect{
				x:      item.pos.x - item.img.width / 2
				y:      item.pos.y - item.img.height / 2
				width:  32
				height: 32
			}
			img:      &item.img
			rotation: irot
		)
	}
}

fn (mut g Game) player_draw() {
	g.ctx.draw_image_with_config(
		img_rect: gg.Rect{
			x: g.player.pos.x - g.player.img.width / 2
			y: g.player.pos.y - g.player.img.height / 2
		}
		img:      &g.player.img
		rotation: f32(math.degrees(g.player.angle))
	)
}

fn (mut g Game) mute_init() {
	g.mute_btn.pos = Vec2{45, gheight - 18}
	g.mute_btn.size = Vec2{60, 33}
	g.mute_btn.label = 'Mute'
	g.mute_btn.label_y = 0
	g.mute_btn.counter = -1
}

fn (mut g Game) mute_trigger() {
	g.song.mute()
	g.mute_btn.label = if g.song.mute { 'unMute' } else { 'Mute' }
	g.mute_btn.shaking = 8
}

fn on_frame(mut g Game) {
	if g.state != .paused {
		g.rotation++
	}
	g.song.work() or {}
	g.player_move()
	g.ctx.begin()
	g.ctx.draw_image(0, 0, gwidth, gheight, g.ctx.get_cached_image_by_idx(g.overlay_img_idx))
	g.items_draw()
	g.player_draw()
	g.bins_draw()
	g.mute_btn.draw(g.ctx)
	g.ctx.draw_text(gwidth - 107, gheight - 34, '${g.state}, day: ${g.day:03}', color: gg.gray)
	g.ctx.draw_text(gwidth - 85, gheight - 18, '${g.player.meters:06}m', color: gg.gray)
	g.ctx.end()
}

fn on_event(e &gg.Event, mut g Game) {
	g.on_develop(e)
	if e.typ == .key_down && e.key_code == .escape {
		g.ctx.quit()
	}
	if e.typ == .char && rune(e.char_code) == `m` {
		g.mute_trigger()
	}
	if e.typ == .char && rune(e.char_code) == `e` {
		g.enable_exit()
	}

	if g.state == .finished {
		return
	}
	pause_key := e.key_code in [.space, .p]
	if g.state == .paused && e.typ == .key_up && pause_key {
		g.change_state(.working)
		return
	}
	if g.state == .working && e.typ == .key_up && pause_key {
		g.change_state(.paused)
		return
	}
	if g.state != .working {
		return
	}
	if e.typ == .key_down {
		g.bins_on_key(e)
		match e.key_code {
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

fn main() {
	mut g := &Game{}
	g.mute_init()
	g.bins_init()
	g.restart()
	g.song.play_ogg_file(asset.get_path('./assets', 'songs/collecting_garbage.ogg'))!
	g.ctx = gg.new_context(
		bg_color:     gg.white
		width:        gwidth
		height:       gheight
		window_title: 'Garbage Collector (LD58)'
		user_data:    g
		init_fn:      init_overlay
		frame_fn:     on_frame
		event_fn:     on_event
		font_path:    asset.get_path('./assets', 'fonts/Imprima-Regular.ttf')
		sample_count: 2
	)
	g.player.img = g.ctx.create_image(asset.get_path('./assets', 'images/player.png'))!
	for i in 0 .. 7 + 1 {
		ipath := asset.get_path('./assets', 'images/${i}.png')
		g.day_images << &gg.Image{
			...g.ctx.create_image(ipath)!
		}
	}
	for path in all_item_paths {
		ipath := asset.get_path('./assets', path)
		g.all_item_images[path] = g.ctx.create_image(ipath)!
	}
	g.background = g.day_images[1]
	g.find_start_and_exit_spots()
	g.ctx.run()
}
