module main

import gg
import os.asset

@[direct_array_access]
fn (mut g Game) copy_background_to_overlay() {
	g.get_b_ptr() or { return }
	sp := unsafe { &gg.Color(g.background.data) }
	tp := unsafe { &gg.Color(g.overlay_img_mem) }
	for y in 0 .. g.background.height {
		for x in 0 .. g.background.width {
			unsafe {
				tp[y * gwidth + x] = sp[y * g.background.width + x]
			}
		}
	}
	g.ctx.update_pixel_data(g.overlay_img_idx, g.overlay_img_mem)
}

fn init_overlay(mut g Game) {
	g.song.play_ogg_file(asset.get_path('./assets', 'songs/collecting_garbage.ogg')) or { return }
	g.player.img = g.ctx.create_image(asset.get_path('./assets', 'images/player.png')) or { return }
	for i in 0 .. 7 + 1 {
		ipath := asset.get_path('./assets', 'images/${i}.png')
		g.day_images << &gg.Image{
			...g.ctx.create_image(ipath) or { return }
		}
	}
	for path in all_item_paths {
		ipath := asset.get_path('./assets', path)
		g.all_item_images[path] = g.ctx.create_image(ipath) or { return }
	}
	g.background = g.day_images[1]
	g.find_start_and_exit_spots()

	g.overlay_img_idx = g.ctx.new_streaming_image(gwidth, gheight, 4, pixel_format: .rgba8)
	g.overlay_img_mem = unsafe { vcalloc(gwidth * gheight * 4) }
	g.copy_background_to_overlay()
}
