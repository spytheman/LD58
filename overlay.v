module main

import gg

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
	g.overlay_img_idx = g.ctx.new_streaming_image(gwidth, gheight, 4, pixel_format: .rgba8)
	g.overlay_img_mem = unsafe { vcalloc(gwidth * gheight * 4) }
	g.copy_background_to_overlay()
}
